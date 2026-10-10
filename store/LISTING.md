# Feed-a-Paw: the store listing

Written 11 October 2026 from what the app actually does: the promise and the
four features on its own front door, and the screens behind them. Nothing here
claims something the build cannot do, and what it cannot do yet is listed at the
bottom, so a listing is never submitted ahead of the app.

Publisher: **Crafted Pixel** (THE PET WELLBEING COMPANY PTY LTD).

## Lengths, against each store's limit

| Field | Limit | Used | |
|---|---:|---:|---|
| name | 30 | 10 | ok |
| subtitle | 30 | 29 | ok |
| short | 80 | 74 | ok |
| promo | 170 | 62 | ok |
| keywords | 100 | 82 | ok |
| full | 4000 | 1094 | ok |

### App name (Play) / Name (App Store)

```
Feed-a-Paw
```

### Subtitle (App Store)

```
Street animals, fed every day
```

### Short description (Play)

```
Follow the rounds that keep street animals fed, and the stories from them.
```

### Promotional text (App Store)

```
See where today's round goes, and meet the animals it reaches.
```

### Keywords (App Store, comma separated, no spaces after commas)

```
street animals,feeding,stray,dogs,cats,rescue,cairo,animal welfare,community,round
```

### Full description (both stores)

```
Street animals, fed every day.

Feed-a-Paw follows the feeding rounds that keep street animals fed: where they go, who they reach, and what the people on them see.

FEEDING SPOTS
See the places a round stops at, by area, and what is usually waiting there.

STORIES FROM THE ROUND
The animals met on the way: the regulars, the new arrivals, and the ones who needed more than a meal.

EDIBLE PLATES
Every meal is served on a plate the animals can eat, so nothing is left on the street behind the round.

THE FOOD TRUCK
Follow the first food truck on its way to Cairo, and how far along it is.

FOR THE FEEDING TEAM
If you are on the team, the app is the round itself. Pick the round you are driving, work through the stops in order, record what was handed out at each one, and photograph who you met. Volunteers who feed on their own can record that too, so the daily count is the real one. Somebody signed in who is not on the team is told so plainly, rather than left at a button that does nothing.

Feed-a-Paw is part of the a-Paw family of apps for animals and the people who look after them.
```

## Not true yet, so not in the listing

- A live map with coordinates (feed_spots.lat and lng are never written; spots are listed by area)
- Following the truck's position (feed_truck_pings.lat and lng are never written)
- Contributing money in-app (no store key, and the standing rule keeps giving language out of all three listings)

## The house rules this copy follows

- No owner's name, email or personal contact address anywhere.
- The three words forbidden by standing instruction (the giving word, the
  organisation word, and the tax phrase) appear nowhere in any of the three
  listings. Written out like this so a grep for them over this folder stays
  clean and needs no exceptions.
- Nothing is called free or paid where no store key exists yet.
- Every claim maps to a screen that is in the build today.

## Still needed from the owner

- A 1024x500 feature graphic (Play).
- Six screenshots per app, per store.
- The 512px store icon upload.
- Category, content rating questionnaire, and the privacy policy URL in each console.
