# Earnings Tracker

A personal planning tool for a self-employed person (živnostník): money earned by working during a chosen window of time funds expenses planned in advance. Logging worked hours gradually shows which planned expenses are already covered.

## Language

### Earning

**Hourly Rate** (Hodinová sadzba):
The single gross amount the user currently earns per worked hour. The user can change it at any time; the new rate applies only to Work Logs recorded from then on.
_Avoid_: wage, price, tariff

**Work Log** (Záznam práce):
A record of hours worked on a given day, carrying the Hourly Rate that was current when it was recorded.
_Avoid_: timesheet, entry, shift

**Earnings** (Zárobok):
Gross money earned in a period, i.e. sum of logged hours × Hourly Rate. Counted when the work is done, regardless of when the client pays. Taxes are not deducted here; they are covered by Budget Items.
_Avoid_: income, revenue, net

### Planning

**Plan** (Plán):
A set of Budget Items to be funded by Earnings made within its Earning Window. Not bound to calendar months. A Plan is never formally closed.
_Avoid_: budget, monthly budget

**Earning Window** (Okno zárabania):
The date range (from–to) of a Plan; Work Logs dated inside it fund that Plan. Earning Windows of different Plans do not overlap, so every Work Log belongs to at most one Plan. A Work Log dated outside every Earning Window is kept and starts funding a Plan once one is created whose window covers that date.
_Avoid_: period, funding month, sprint

**Budget Item** (Položka plánu):
One planned expense with a target amount, e.g. mortgage, food, investing. Taxes and mandatory insurance contributions (odvody) are ordinary Budget Items, placed first.
_Avoid_: expense, category, envelope

**Template** (Šablóna):
A reusable set of Budget Items from which a new Plan can be started. Changing it does not affect existing Plans.
_Avoid_: default plan, recurring budget

### Progress

**Funding Order** (Poradie pokrývania):
The user-defined sequence of Budget Items in a Plan; Earnings fill items one after another in this order, each fully before the next.
_Avoid_: priority, ranking

**Covered** (Pokrytá):
A Budget Item is Covered once Earnings have fully filled it in the Funding Order. Items left uncovered when an Earning Window ends stay visible as a fact for the user to reflect on; they are not carried over automatically.
_Avoid_: paid, funded, done

**Essentials Line** (Hranica základu):
A single divider in the Funding Order. Budget Items above it are Essentials (needs); items below it are Extras (nice-to-haves, e.g. vacation, extra investing). Both are ordinary Budget Items.
_Avoid_: bonus items, stretch goals, wishlist

**Unassigned Earnings** (Nepriradený zárobok):
Earnings in a Plan beyond the total of all its Budget Items; money without a purpose yet, which the user is invited to assign by adding or raising Budget Items. Plans can be edited at any time during their Earning Window.
_Avoid_: surplus, leftover, profit

**Next Milestone** (Najbližší cieľ):
The first Budget Item in the Funding Order that is not yet Covered, expressed as the hours still needed to cover it at the current Hourly Rate.
_Avoid_: goal, target, next item
