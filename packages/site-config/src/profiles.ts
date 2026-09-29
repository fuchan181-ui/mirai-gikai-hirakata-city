import { hirakataCityProfile } from "./profiles/hirakata-city";
import { numazuCityProfile } from "./profiles/numazu-city";
import { shizuokaPrefProfile } from "./profiles/shizuoka-pref";
import type { SiteProfileRegistry } from "./types";

export { hirakataCityProfile, numazuCityProfile, shizuokaPrefProfile };

export const siteProfiles = {
  "hirakata-city": hirakataCityProfile,
  "numazu-city": numazuCityProfile,
  "shizuoka-pref": shizuokaPrefProfile,
} as const satisfies SiteProfileRegistry;
