# Concentrix iX-Suite Rebrand Guide

## Quick Reference

**Site Name:** Concentrix iX-Suite (short: iX-Suite)
**Port:** 9800
**URL:** https://ixsuite.cnxlab.us/
**Data:** `docker/LocalLiveDockerData/`

### Brand Colors
| Purpose | Color |
|---------|-------|
| Primary | `#003D5B` |
| Tonal Alt 1 | `#08576D` |
| Tonal Alt 2 | `#007380` |
| Button Background | `#24E2CB` |
| Button Text | `#003D5B` |
| Button Hover | `#fbca1b` (gold) |

### Source Assets
Location: `C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite`

---

## Files Modified for Rebrand

### 1. Logo/Image Assets (copy from source)
```
packages/ui/src/assets/images/
  - flowise_white.svg  <- logo.svg
  - flowise_dark.svg   <- logo-dark.svg
  - flowise_logo.png   <- logo.png
  - flowise_logo_dark.png <- logo-dark.png
  - robot.png          <- avitar.png

packages/ui/public/
  - favicon.ico        <- icon.png
  - favicon-16x16.png  <- icon.png
  - favicon-32x32.png  <- icon.png
  - logo192.png        <- icon.png
  - logo512.png        <- icon.png
```

### 2. Site Name & Meta
**packages/ui/public/index.html** - Title, meta tags, theme-color
**packages/ui/public/manifest.json** - PWA name

### 3. Theme Colors
**packages/ui/src/assets/scss/_themes-vars.module.scss** - Primary/secondary colors
**packages/ui/src/themes/compStyleOverride.js** - Button styling

### 4. Email Templates
**packages/server/src/enterprise/emails/*.html** - FlowiseAI -> iX-Suite

### 5. Button Component
**packages/ui/src/ui-component/button/StyledButton.jsx** - Brand colors for buttons

### 6. Index.html (Vite)
**packages/ui/index.html** - Title, meta tags (used by Vite build)

### 7. NavItem Beta Chip
**packages/ui/src/layout/MainLayout/Sidebar/MenuList/NavItem/index.jsx** - BETA chip colors

### 8. Theme Index (text colors)
**packages/ui/src/themes/index.js** - menuSelected, menuSelectedBack, darkTextPrimary colors

### 9. Header (GitHub stars removal)
**packages/ui/src/layout/MainLayout/Header/index.jsx** - Remove GitHubStarButton

---

## How to Rebuild After Flowise Upgrade

### Step 1: Pull Latest Flowise
```bash
cd C:\Users\DavidSoden\Flowise
git fetch origin
git pull origin main
```

### Step 2: Reapply Brand Assets
```bash
# Copy logos
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\logo.svg" "packages/ui/src/assets/images/flowise_white.svg"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\logo-dark.svg" "packages/ui/src/assets/images/flowise_dark.svg"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\logo.png" "packages/ui/src/assets/images/flowise_logo.png"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\logo-dark.png" "packages/ui/src/assets/images/flowise_logo_dark.png"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\avitar.png" "packages/ui/src/assets/images/robot.png"

# Copy favicons
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\icon.png" "packages/ui/public/favicon.ico"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\icon.png" "packages/ui/public/favicon-16x16.png"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\icon.png" "packages/ui/public/favicon-32x32.png"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\icon.png" "packages/ui/public/logo192.png"
cp "C:\Users\DavidSoden\OneDrive - Concentrix Corporation\CNX Pictures\CNX LOGOs\ixSuite\icon.png" "packages/ui/public/logo512.png"
```

### Step 3: Reapply Code Changes
The following files need manual edits after upgrade (check git diff):

1. **packages/ui/public/index.html** - Update title/meta to "Concentrix iX-Suite"
2. **packages/ui/index.html** - Update title/meta (Vite entry point)
3. **packages/ui/public/manifest.json** - Update name to "iX-Suite"
4. **packages/ui/src/assets/scss/_themes-vars.module.scss** - Update colors
5. **packages/ui/src/themes/index.js** - Update menuSelected, menuSelectedBack, darkTextPrimary to use brand colors
6. **packages/ui/src/themes/compStyleOverride.js** - Update button and hover styles
7. **packages/ui/src/ui-component/button/StyledButton.jsx** - Update button brand colors (#24E2CB bg, #003D5B text)
8. **packages/ui/src/layout/MainLayout/Sidebar/MenuList/NavItem/index.jsx** - BETA chip colors
9. **packages/ui/src/layout/MainLayout/Header/index.jsx** - Remove GitHub stars button
10. **packages/server/src/enterprise/emails/*.html** - Update branding

### Step 4: Rebuild Docker
```bash
cd docker
docker-compose -f docker-compose.local.yml down
docker-compose -f docker-compose.local.yml build --no-cache
docker-compose -f docker-compose.local.yml up -d
```

---

## Docker Configuration

### Dockerfile.local (builds from source)
Located at: `docker/Dockerfile.local`
- Uses pnpm to install dependencies
- Runs `pnpm build` to compile all packages
- Entry: `node bin/run start`

### docker-compose.local.yml
- Image: `concentrix-ix-suite:latest`
- Port: 9800
- Data volume: `./LocalLiveDockerData:/root/.flowise`

---

## Troubleshooting

### Changes not appearing
1. Hard refresh: Ctrl+Shift+R
2. Clear browser cache
3. Try incognito window
4. Check container logs: `docker logs docker-flowise-1`

### Container won't start
Check entrypoint - must be `node bin/run start` (oclif CLI)

### Build fails
- Ensure pnpm v9+ installed in container
- Check node_modules copied correctly
