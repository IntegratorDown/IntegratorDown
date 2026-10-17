import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/** IntegratorDown 开源仓库地址 */
export const GITHUB_REPO_URL = "";

