import { createClient } from "@supabase/supabase-js";
import type { Database } from "../types/supabase.types";

// Secret key client for server-side operations that bypass RLS
export function createAdminClient() {
  const secretKey =
    process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
  return createClient<Database>(process.env.SUPABASE_URL!, secretKey!);
}
