import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type VerifyReceiptResponse = {
  status: number;
  environment?: string;
  receipt?: {
    bundle_id?: string;
    in_app?: Array<Record<string, unknown>>;
  };
  latest_receipt_info?: Array<Record<string, unknown>>;
};

type VerifyRequest = {
  productId?: string;
  transactionId?: string;
  platform?: string;
  source?: string;
  serverVerificationData?: string;
  localVerificationData?: string;
};

const productionVerifyUrl = "https://buy.itunes.apple.com/verifyReceipt";
const sandboxVerifyUrl = "https://sandbox.itunes.apple.com/verifyReceipt";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: "Supabase function environment is incomplete" }, 500);
  }

  const authorization = req.headers.get("Authorization") ?? "";
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return json({ error: "Authentication required" }, 401);
  }

  const body = (await req.json().catch(() => ({}))) as VerifyRequest;
  const productId = body.productId?.trim();
  const transactionId = body.transactionId?.trim();
  const platform = body.platform?.trim() || "ios";
  const source = body.source?.trim() || "app_store";
  const receiptData =
    body.serverVerificationData?.trim() ||
    body.localVerificationData?.trim() ||
    "";

  if (!productId || !transactionId || !receiptData) {
    return json({ error: "Missing purchase verification fields" }, 400);
  }

  if (platform !== "ios" || source !== "app_store") {
    return json({ error: "Only App Store coin purchases are supported" }, 400);
  }

  const appStoreVerification = await verifyAppStoreReceipt({
    receiptData,
    productId,
    transactionId,
  });

  if (!appStoreVerification.ok) {
    const { data: existingReceipt } = await serviceClient
      .from("purchase_receipts")
      .select("status")
      .eq("platform", platform)
      .eq("transaction_id", transactionId)
      .maybeSingle();

    if (existingReceipt?.status !== "verified") {
      await serviceClient.from("purchase_receipts").upsert(
        {
          owner_id: user.id,
          platform,
          product_id: productId,
          transaction_id: transactionId,
          status: "rejected",
          raw_receipt_hash: await sha256(receiptData),
          context: {
            source,
            reason: appStoreVerification.reason,
            apple_status: appStoreVerification.status,
          },
        },
        { onConflict: "platform,transaction_id" },
      );
    }
    return json({ error: appStoreVerification.reason }, 400);
  }

  const { data, error } = await serviceClient.rpc(
    "grant_verified_coin_purchase",
    {
      target_owner_id: user.id,
      target_product_id: productId,
      target_transaction_id: transactionId,
      target_platform: platform,
      target_raw_receipt_hash: await sha256(receiptData),
      verification_context: {
        source,
        apple_environment: appStoreVerification.environment,
        apple_status: appStoreVerification.status,
      },
    },
  );

  if (error) {
    return json({ error: error.message }, 500);
  }

  return json(data);
});

async function verifyAppStoreReceipt({
  receiptData,
  productId,
  transactionId,
}: {
  receiptData: string;
  productId: string;
  transactionId: string;
}): Promise<{
  ok: boolean;
  reason?: string;
  status?: number;
  environment?: string;
}> {
  const sharedSecret = Deno.env.get("APPLE_SHARED_SECRET");
  const bundleId = Deno.env.get("APPLE_BUNDLE_ID");
  const production = await callAppleVerifyReceipt(
    productionVerifyUrl,
    receiptData,
    sharedSecret,
  );
  const response = production.status === 21007
    ? await callAppleVerifyReceipt(sandboxVerifyUrl, receiptData, sharedSecret)
    : production;

  if (response.status !== 0) {
    return {
      ok: false,
      reason: "Apple receipt verification failed",
      status: response.status,
      environment: response.environment,
    };
  }

  if (bundleId && response.receipt?.bundle_id !== bundleId) {
    return {
      ok: false,
      reason: "Receipt bundle identifier mismatch",
      status: response.status,
      environment: response.environment,
    };
  }

  const purchases = [
    ...(response.latest_receipt_info ?? []),
    ...(response.receipt?.in_app ?? []),
  ];
  const matchingPurchase = purchases.find((purchase) => {
    const purchaseProductId = purchase["product_id"];
    const purchaseTransactionId = purchase["transaction_id"];
    return purchaseProductId === productId &&
      purchaseTransactionId === transactionId;
  });

  if (!matchingPurchase) {
    return {
      ok: false,
      reason: "Receipt does not contain the requested coin pack transaction",
      status: response.status,
      environment: response.environment,
    };
  }

  return {
    ok: true,
    status: response.status,
    environment: response.environment,
  };
}

async function callAppleVerifyReceipt(
  url: string,
  receiptData: string,
  sharedSecret?: string,
): Promise<VerifyReceiptResponse> {
  const body: Record<string, unknown> = {
    "receipt-data": receiptData,
    "exclude-old-transactions": true,
  };
  if (sharedSecret) {
    body.password = sharedSecret;
  }

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  return await response.json() as VerifyReceiptResponse;
}

async function sha256(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
