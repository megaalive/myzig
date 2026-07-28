# AZIG-OWN-005 — adjacent-line permits for ptrcast

## Summary

Rule text already promised an **adjacent** safety/permit remark, but the detector
only inspected the cast line. azig callback / FFI sites often put
`// myzig.permit(ptrcast): …` on the line above `@ptrCast` / `@alignCast`.

## Candidate rule / limit

- Accept permit/safety markers on previous, current, or next line
- Keep kind matching for structured permits
- Still convention ceiling — not UB proof

## False-positive / fitting risk

A permit two lines away still flags (intentionally strict adjacency).
