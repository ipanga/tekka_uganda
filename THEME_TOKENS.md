# Tekka Theme Tokens

## Primary Orange (Global)
- Primary: `#F97316` | `hsl(24 95% 53%)` | `Color(0xFFF97316)`
- Hover: `#EA580C` | `hsl(23 90% 48%)` | `Color(0xFFEA580C)`
- Pressed: `#C2410C` | `hsl(20 88% 40%)` | `Color(0xFFC2410C)`
- Light: `#FDBA74` | `hsl(33 96% 73%)` | `Color(0xFFFDBA74)`
- Dark: `#9A3412` | `hsl(15 79% 34%)` | `Color(0xFF9A3412)`
- Disabled: `#FED7AA` | `hsl(31 97% 83%)` | `Color(0xFFFED7AA)`

## Design Token Format
```json
{
  "color": {
    "primary": {
      "50": "#FFF7ED",
      "100": "#FFEDD5",
      "200": "#FED7AA",
      "300": "#FDBA74",
      "400": "#FB923C",
      "500": "#F97316",
      "600": "#EA580C",
      "700": "#C2410C",
      "800": "#9A3412",
      "900": "#7C2D12",
      "950": "#431407",
      "hover": "#EA580C",
      "pressed": "#C2410C",
      "disabled": "#FED7AA"
    },
    "secondary": { "500": "#334155" },
    "success": { "500": "#16A34A" },
    "warning": { "500": "#D97706" },
    "error": { "500": "#DC2626" },
    "background": "#F8FAFC",
    "surface": {
      "default": "#FFFFFF",
      "elevated": "#F1F5F9"
    },
    "border": "#E2E8F0",
    "text": {
      "primary": "#1E293B",
      "secondary": "#64748B",
      "muted": "#94A3B8"
    }
  }
}
```

## Web Theme (Light Mode Only)
The web dashboards (User and Admin) use Light Mode exclusively.
Dark mode is supported only in the Flutter mobile app.
