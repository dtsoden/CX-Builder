# v4.0.0-branding Migration Guide

## Version Hierarchy

```
Flowise Upstream (3.0.12)
    └── v3.0.12-customized (iX-Suite base customizations)
            └── v4.0.0-branding (Dual-brand support: iX-Suite / CX-Builder)
```

## Current State
- **Base Version:** v3.0.12-customized
- **Feature Version:** 4.0.0-branding
- **Feature:** Dual-brand support with dynamic text/image swapping

## What This Version Adds

### Branding Toggle Feature
Allows switching between two brands via settings:

| Feature | iX-Suite (Default) | CX-Builder |
|---------|-------------------|------------|
| Chatflows | iX-Hello | Chatflows |
| Agentflows | iX-Hero | Agentflows |
| Document Stores | iX-Wisdom | Document Stores |
| Empty State Images | ixsuite_empty.svg | cxbuilder_empty.svg |

### Brand State Management
- Location: Redux `customization.brand`
- Values: `'ix-suite'` (default) or `'cx-builder'`

### Standard Pattern for Brand-Aware Components
```javascript
const customization = useSelector((state) => state.customization)
const brand = customization?.brand
const chatflowLabel = brand === 'cx-builder' ? 'Chatflow' : 'iX-Hello'
```

## Files in this folder
- `CUSTOMIZATION_MANIFEST.json` - Complete inventory of branding changes
- `README.md` - This file

## Migration Strategy

### When Upgrading to New Flowise Version

1. **Start with v3.0.12-customized migration first**
   - Apply all base customizations from `../v3.0.12-customized/.migration/`
   - This includes theme, server changes, components, etc.

2. **Then apply branding modifications**
   - Copy added files (cxbuilder_empty.svg, cxbuilder_empty_dark.svg)
   - Apply brand-aware code changes to UI components
   - Search for `customization?.brand` to find all brand-aware code

3. **Test both brands**
   - Toggle brand setting in UI
   - Verify all text labels switch correctly
   - Verify empty state images switch correctly

## Key Modified Files

### Settings/Menu Transformation
- `views/settings/index.jsx` - `getBrandAwareTitle()` function
- `ui-component/button/FlowListMenu.jsx` - Brand-aware context menu
- `menu-items/settings.js`, `agentsettings.js` - Source labels (transformed at render)

### Dialogs
- `ExportAsTemplateDialog.jsx` - `getFlowTypeLabel()` for flow types
- `ChatflowConfigurationDialog.jsx` - Tab labels
- `AgentflowGeneratorDialog.jsx` - Error messages, alt text
- `SaveChatflowDialog.jsx` - Placeholder text

### Views
- All main views (agentflows, chatflows, docstore)
- Canvas views (index, CanvasHeader, AddNodes)
- Various detail views and dialogs

## Inherits From Base
All customizations from v3.0.12-customized are inherited:
- Theme/styling customizations
- Server-side route changes
- Passport middleware changes
- Postgres driver customizations
- Azure Reranker components
- Dynamic marketplace folder system
- Email templates
- Favicons and logos

See `../v3.0.12-customized/.migration/CUSTOMIZATION_MANIFEST.json` for complete list.
