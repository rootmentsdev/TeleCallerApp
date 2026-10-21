# JustDial Count Fix

## Problem
The JustDial tab in the Lead Screen was showing a hardcoded count of "3" instead of the actual number of JustDial leads.

## Root Cause
In `lead_screen.dart`, the JustDial category card was using a hardcoded value:
```dart
count: 3,  // ← Hardcoded!
```

## Solution
Created a new method `getJustDialLeadsCount()` in the `LeadScreenController` to dynamically count JustDial leads, similar to existing methods for other