# CSA Verification Checklist

Add these test cases to catch arithmetic bugs in the CSA verification suite:

- [ ] **Test A**: `csa_en = 0`
  - Expected: `stress_score = 0`
- [ ] **Test B**: all sensors = 255, all weights = 255
  - Expected: No overflow, No X values
- [ ] **Test C**: Only moisture active
  - Verify: `stress_score` changes
- [ ] **Test D**: Only light active
  - Verify: `stress_score` changes
- [ ] **Test E**: All weights = 0
  - Expected: `stress_score = 0`
