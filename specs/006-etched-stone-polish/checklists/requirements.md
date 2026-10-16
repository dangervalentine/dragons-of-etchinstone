# Specification Quality Checklist: Etched Stone and Ether Rifts

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-10-15
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- Iteration 1 fixed three wording issues: "MAY" used as a prohibition in FR-005 and
  FR-019, and an unclear phrase in SC-004.
- The open questions carried from the assessment are settled as assumptions, not
  markers:
  - Zones may be rearranged, keeping the same jobs.
  - Stone may be drawn in code, with generated textures as a fallback.
  - The owner is the sole judge of preference.
- Several criteria rely on the owner's judgement (SC-003, SC-006) or on a viewer
  (SC-004, SC-005), because there is no player population. They are still verifiable
  as yes/no checks.
- "Large unused area" (FR-005) is made concrete by SC-002's "no more than about a
  third empty".

## Revision 2 (2026-10-15, after the stage 2 review)

The checklist was re-run against the revised spec ("Raised Stone and the Math in
Plain Sight") and all items still pass.

- The only clarification marker (what "printed format" means for the cards) was
  resolved with the owner: nothing is off, so the requirement was dropped (FR-017
  now keeps the 005 faces).
- Two named tools are owner constraints, not implementation choices: ComfyUI (the
  owner's choice of generator) and "the engine's own figure" (the rule that the math
  box explains the result and never computes it).
- SC-002 (terms add up to the engine's totals in 100% of states) and SC-003 (a first-time
  viewer finds the Hardship's effect within 10 seconds) replace the old role-rail area
  criterion.
- The plan, data model, contracts, quickstart and tasks were written for revision 1.
  They need `/speckit-plan` and `/speckit-tasks` to be re-run before more
  implementation.
