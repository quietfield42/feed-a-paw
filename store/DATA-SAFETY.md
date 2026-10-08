# Play Console — Data safety answers (Feed-a-Paw)

Google rejects apps whose Data safety answers do not match what the app does,
and the answers must agree with the privacy policy. Everything below was read
from the code and the built manifest on 8 October 2026, not recalled.

Privacy policy: https://spotapaw.github.io/care-a-paw-site/feed/privacy.html
Delete account: https://spotapaw.github.io/care-a-paw-site/account/

## The three opening questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — every call to Supabase is HTTPS |
| Do you provide a way for users to request that their data be deleted? | **Yes** — the account page above |

## What the app declares

Declared Android permissions, read from the built manifest: **INTERNET only.**
No camera permission, no storage permission, **no location permission.**

The camera is reached through the system camera app, which is why no camera
permission is declared. Do not add one — declaring it would force a runtime
request the app does not make.

## Data types

Tick only these. Everything is collected, **nothing is shared** — Supabase is a
processor acting on our instructions, which Play does not count as sharing.
Nothing is sold, and there is no advertising, analytics, or tracking SDK in the
app at all.

| Category | Type | Collected | Optional? | Purpose |
|---|---|---|---|---|
| Personal info | Email address | Yes | Required for an account; the app is fully usable without one | Account management, App functionality |
| Personal info | User IDs | Yes | Required for an account | Account management, App functionality |
| Photos and videos | Photos | Yes | Optional | App functionality |
| App activity | Other user-generated content | Yes | Optional | App functionality |

**Photos.** Taken by the team at a stop, of streets and animals. They go to the
`feed-photos` bucket, which is **public** — anybody with the address can open
one — and they are shown to everybody in the app. That is deliberate; it is how
the rounds are reported. Say so in the policy and keep saying it.

**Other user-generated content** covers what a round records: the spot, meals
handed out, animals seen, the note, and the stories the team write.

## Leave these UNTICKED, and why

- **Location** — the app never asks for the location permission and never reads
  it. Spots are named by a person typing a name.
- **Financial info** — nothing is bought in the app and nothing ever will be.
  Supporting happens on the website, outside the app. This is a hard constraint:
  Apple and Google do not permit in-app donations for an organisation that is
  not a registered charity.
- **Messages** — there are none. Nobody can send anybody anything, which is also
  why the app carries no report-and-block tools.
- **Device or other IDs** — nothing collects one. No analytics, no advertising
  ID, no crash reporting.
- **Health, Contacts, Calendar, Audio, Files, Web browsing, App info and
  performance** — none of it is touched.

## One thing a reviewer may ask about

`google_fonts` fetches a typeface from Google at first run, so Google sees the
device's IP address. That is not declarable user data and no other app in the
family declares it either. If it is ever queried, the honest answer is that the
app requests a font file and stores nothing.

## When anything changes

Feed-a-Paw sells nothing, so the payment row never changes. If a future version
ever adds a message between two people, the Messages type and a report-and-block
route both become required, by Google's policy and by Apple's.

Written 8 Oct 2026.
