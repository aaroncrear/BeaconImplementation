# "Traffic-Light-System" – Release Notes

## Requirements

Users need to see a record's contact status at a glance, as a colored flag icon, on records, in list views and in reports.

- Add an icon for each status: **Blacklisted**, **Customer**, **Do Not Call**, **Do Not Email** and **Do Not Contact**.
- Store the icons in Salesforce so formula fields can display them with the `IMAGE()` function.

## Release Notes

### Flag icon static resources

Five **static resources** were added, one for each status icon. Each is a PNG image, 32 pixels high, showing a colored flag and the status label in bold on a white rounded badge with a light gray border:

| Static Resource | Flag Color | Text |
|-----------------|------------|------|
| `Blacklisted` | Black | Blacklisted |
| `Customer` | Green | Customer |
| `Do_Not_Call` | Orange | Do Not Call |
| `Do_Not_Email` | Orange | Do Not Email |
| `Do_Not_Contact` | Red | Do Not Contact |

Each resource has the description "Used in formula fields to display icons on records, list views and reports."

The icons were drawn so they stay readable anywhere they appear:

- **White badge background.** The first version had a transparent background, so the black "Blacklisted" text disappeared on dark backgrounds. The white badge keeps every label readable on light and dark pages.
- **Double resolution.** The images are 32 pixels high, twice the 16-pixel size of a typical list view or report row. When a formula shows them at 16 pixels, they stay sharp on high-resolution screens instead of looking blurry.
- **Readable text colors.** Each label uses a darker shade of its flag color so the text has enough contrast against white (at least 4.5:1, the WCAG AA standard). The flags keep the brighter colors.

Static resources were used because Salesforce serves them from a stable URL, `/resource/<Name>`, which the `IMAGE()` function can reference in a formula field. Unlike Documents or Files, they deploy with the rest of the metadata, so the icons stay the same in every org.

The cache control is set to **Public**. This lets Salesforce cache the images, so list views and reports with many rows load quickly. The icons contain no sensitive data.

### Using the icons in a formula field

A Text formula field can show an icon with the `IMAGE()` function. For example:

```
IMAGE("/resource/Customer", "Customer")
```

Without a size, the icon shows at its full 32-pixel height. To fit it into a standard row, set the height to 16 pixels and leave out the width, so the icon keeps its proportions:

```
IMAGE("/resource/Customer", "Customer", 16)
```

No formula fields use the icons yet. They will be added in a later change.

## Acceptance Criteria

1. In **Setup → Static Resources**, confirm these five static resources exist: **Blacklisted**, **Customer**, **Do_Not_Call**, **Do_Not_Email** and **Do_Not_Contact**.
2. For each one, confirm:
   1. **MIME Type** is `image/png`.
   2. **Cache Control** is **Public**.
   3. **Description** is "Used in formula fields to display icons on records, list views and reports."
3. For each one, click **View file** and confirm the image shows the correct flag and bold text on a white badge, sharp and readable:
   1. **Blacklisted**: black flag, "Blacklisted".
   2. **Customer**: green flag, "Customer".
   3. **Do_Not_Call**: orange flag, "Do Not Call".
   4. **Do_Not_Email**: orange flag, "Do Not Email".
   5. **Do_Not_Contact**: red flag, "Do Not Contact".
4. To confirm the icons work in a formula field, create a test Text formula field in a sandbox with the formula `IMAGE("/resource/Customer", "Customer")`.
   1. Open a record and confirm the green Customer flag shows.
   2. Add the field to a list view and confirm the flag shows.
   3. Add the field to a report and confirm the flag shows.
   4. Change the formula to `IMAGE("/resource/Customer", "Customer", 16)`. Confirm the icon shows at the smaller size, keeps its proportions and is still sharp and readable.
   5. Delete the test field after testing.

## Post Deployment Items

None

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Traffic-Light-System

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | StaticResource | N/A | Blacklisted | Blacklisted | Created | Black flag icon with the text "Blacklisted". Used in formula fields to display icons on records, list views and reports. |
| 2 | StaticResource | N/A | Customer | Customer | Created | Green flag icon with the text "Customer". Used in formula fields to display icons on records, list views and reports. |
| 3 | StaticResource | N/A | Do_Not_Call | Do_Not_Call | Created | Orange flag icon with the text "Do Not Call". Used in formula fields to display icons on records, list views and reports. |
| 4 | StaticResource | N/A | Do_Not_Email | Do_Not_Email | Created | Orange flag icon with the text "Do Not Email". Used in formula fields to display icons on records, list views and reports. |
| 5 | StaticResource | N/A | Do_Not_Contact | Do_Not_Contact | Created | Red flag icon with the text "Do Not Contact". Used in formula fields to display icons on records, list views and reports. |
