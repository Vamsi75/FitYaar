# FitYaar Pro — how it works + Razorpay go-live

Pro is **built and live** as an entitlement. Individuals and gyms can already be made Pro today
(super-admin grant / gym seat plan / promo code). Only the **self-serve online payment** (Razorpay)
is dormant — it flips on with API keys, no code changes to the entitlement core.

## Model (already shipped)
- **Pro is an entitlement, not a role.** `User.role` stays USER/ADMIN. Pro is computed per request from
  either a personal `subscriptions` row **or** the user's gym plan — see
  `EntitlementService` (`com.fityaar.subscription`).
- Sources: `MANUAL` (super-admin grant), `PROMO` (code), `GYM` (gym-sponsored seat plan),
  `RAZORPAY` (online — Phase 2).
- Surfaced to clients two ways: on the **login/register response** (`pro`, `plan`, `until`) and via
  `GET /api/me/entitlements`. Mobile reads it in `AuthProvider.isPro` and refreshes on bootstrap /
  when opening the Go-Pro screen.
- Server guard for Pro-only endpoints: `EntitlementService.requirePro(user)` → 403.

## Ways to make someone Pro today (no payment provider needed)
- **Grant (comp/influencer/support):** super-admin console → "Grant Pro to a user" →
  `POST /api/subscriptions/grant {email, plan}` (MONTHLY/YEARLY/LIFETIME).
- **Gym-sponsored (B2B):** super-admin console → "Gym billing" → set a gym's tier + `ACTIVE` status +
  period + paid seats (`POST /api/admin/gyms/{id}/plan`). Every ACTIVE member of that gym inherits Pro
  while the plan is active. `GET /api/admin/gyms/{id}/seats` shows usage + over-cap.
- **Promo code:** set `PROMO_CODES=CODE1,CODE2`; user redeems via `POST /api/subscriptions/redeem
  {code}` → 1 year of Pro.

## Razorpay go-live (Phase 2 — when you have keys)
The web checkout page (`FitYaar-Web/checkout.html`) and backend (`subscription/payment/*`) are
scaffolded and dormant behind a flag.

1. **Create a Razorpay account**; get **Key ID + Key Secret** (test mode first) and set a **Webhook
   secret**.
2. **Backend env:**
   - `PAYMENT_ENABLED=true`
   - `RAZORPAY_KEY_ID=...`, `RAZORPAY_KEY_SECRET=...`, `RAZORPAY_WEBHOOK_SECRET=...`
   On boot, `PaymentService` logs "Payment enabled" and the webhook controller registers
   (`@ConditionalOnProperty`). The webhook path `/api/payments/webhook/**` is already public
   (auth = HMAC signature, verified by `PaymentSignature`).
3. **Add the Razorpay SDK** (`com.razorpay:razorpay-java`) to `pom.xml` and implement
   `PaymentService.createOrder` (Orders API) + parse the webhook event in `RazorpayWebhookController`
   → `SubscriptionService.recordFromProvider(email, plan, providerRef)` (already idempotent on
   `provider_ref`).
4. **Web checkout:** in `checkout.html`, mount Razorpay Checkout with the returned order + `key_id`.
   Configure the webhook URL in the Razorpay dashboard to `https://<api-host>/api/payments/webhook`.
5. **Mobile:** already opens `WEB_BASE_URL/checkout.html?plan=<PLAN>` via `url_launcher`. Set
   `--dart-define=WEB_BASE_URL=https://app.fityaar.com` for release builds.
6. **Recurring (autopay):** use Razorpay **Subscriptions** (UPI AutoPay / card e-mandate) instead of
   one-off Orders when you want auto-renewal; the webhook events (`subscription.charged`) feed the same
   `recordFromProvider`.

## Store-policy notes
- **Web + Android**: selling Pro on the web (Razorpay) avoids the 15–30% store cut and is the
  India-first default. Gym B2B is business-to-business — no store rules apply at all.
- **iOS**: Apple restricts steering users to web payment for digital goods (region-dependent). Safest
  is web-signup that the iOS app merely reflects; add Apple IAP later only if iOS conversion warrants
  eating the fee.

## Not yet done
- Live Razorpay order creation + webhook event parsing (steps 3–4 above).
- iOS Apple IAP. Analytics module (`com.fityaar.analytics` is an empty placeholder).
