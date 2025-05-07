# Teal Theme UI Components Guide

## Color Palette Applied

### Light Mode
- **Primary**: ![#009688](https://via.placeholder.com/15/009688/000000?text=+) `#009688` (Teal-500)
- **Primary Container**: ![#E0F2F1](https://via.placeholder.com/15/E0F2F1/000000?text=+) `#E0F2F1` (Teal-50)
- **OnPrimary**: ![#FFFFFF](https://via.placeholder.com/15/FFFFFF/000000?text=+) `#FFFFFF` (White)
- **Surface**: ![#FDFBFF](https://via.placeholder.com/15/FDFBFF/000000?text=+) `#FDFBFF` (Near white)

### Dark Mode
- **Primary**: ![#4DB6AC](https://via.placeholder.com/15/4DB6AC/000000?text=+) `#4DB6AC` (Teal-300)
- **Primary Container**: ![#005047](https://via.placeholder.com/15/005047/000000?text=+) `#005047` (Dark teal)
- **OnPrimary**: ![#003731](https://via.placeholder.com/15/003731/000000?text=+) `#003731` (Dark text)
- **Surface**: ![#1A1C1B](https://via.placeholder.com/15/1A1C1B/000000?text=+) `#1A1C1B` (Dark surface)

## UI Components with Teal Theme

### 1. AppBar
```dart
AppBar(
  title: Text('FlashMaster'),
  // Automatically uses theme's primary color (teal)
)
```
- Light Mode: Teal-500 background with white text
- Dark Mode: Surface color with teal-300 accents

### 2. Elevated Buttons
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Start Review'),
)
```
- Light Mode: Teal-500 background, white text
- Dark Mode: Teal-300 background, dark text (#003731)

### 3. Floating Action Button
```dart
FloatingActionButton(
  onPressed: () {},
  child: Icon(Icons.add),
)
```
- Light Mode: Teal-500 background, white icon
- Dark Mode: Teal-300 background, dark icon

### 4. Selection Controls

**Switch**:
```dart
Switch(
  value: true,
  onChanged: (bool value) {},
)
```
- Active: Teal track and thumb
- Inactive: Grey track and thumb

**Checkbox**:
```dart
Checkbox(
  value: true,
  onChanged: (bool? value) {},
)
```
- Checked: Teal checkmark and border
- Unchecked: Grey border

### 5. Progress Indicators
```dart
CircularProgressIndicator()
LinearProgressIndicator()
```
- Both use teal color for progress indication

### 6. Cards
```dart
Card(
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.cardGradientStart,  // Teal-50
          AppColors.cardGradientEnd,    // Teal-100
        ],
      ),
    ),
  ),
)
```
- Light Mode: Teal gradient (Teal-50 to Teal-100)
- Dark Mode: Dark teal gradient

### 7. Text Fields
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Enter text',
    border: OutlineInputBorder(),
  ),
)
```
- Focus state: Teal border
- Label: Teal when focused
- Cursor: Teal
- Selection: Teal with transparency

## Usage Guidelines

1. **Primary Actions**: Use teal for primary actions and key interactive elements
2. **Secondary Actions**: Continue using purple for interview-related features
3. **Contrast**: Ensure text on teal backgrounds maintains WCAG AA compliance
4. **Consistency**: Use theme colors throughout the app rather than hardcoded values

## Visual Example

A flashcard deck card now appears with:
- Teal gradient background
- Teal progress indicator
- Teal action buttons
- Purple accent for interview mode toggle

This creates a cohesive visual hierarchy while maintaining the app's dual functionality (deck review vs interview practice).