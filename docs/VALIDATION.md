# Validation

- Swift release compilation, ad-hoc signing and `.pkg` generation passed.
- Generated HEIC fixtures converted to PNG and JPG with dimensions and orientation preserved.
- Duplicate output names receive suffixes.
- Transparent PNG to JPG uses a white background.
- Invalid input throws a conversion error.
- App launched successfully; compact window and initial disabled Copy/Save states verified through accessibility and screenshot.
- File picker conversion completed and enabled Copy/Save.

Manual checks still needed: multiple-file drag from Finder, paste from Photos and browsers, paste copied results into receiving apps, save to permission-restricted folders, very large batches, and installer execution on a clean Mac. No notarization or Developer ID validation performed.

In this environment HEIC fixture generation needs an unsandboxed test run to reach Apple's image encoder service.
