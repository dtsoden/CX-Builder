# CX-Builder Migration Guide

## Version Hierarchy

```
Flowise Upstream (3.0.12)
    └── v3.0.12-customized (Base customizations)
            └── v4.0.0-branding (CX-Builder exclusive branding)
```

## Current State
- **Base Version:** v3.0.12-customized
- **Feature Version:** 4.0.0-branding
- **Brand:** CX-Builder™ (exclusive - no dual-brand toggle)

## Terminology

| Feature | Label |
|---------|-------|
| Chatflows | Chatflows |
| Agentflows | Agentflows |
| Document Stores | Document Stores |
| Empty State Images | cxbuilder_empty.svg |

## Files in this folder
- `CUSTOMIZATION_MANIFEST.json` - Complete inventory of customization changes
- `README.md` - This file

## Migration Strategy

### When Upgrading to New Flowise Version

1. **Start with v3.0.12-customized migration first**
   - Apply all base customizations from `../v3.0.12-customized/.migration/`
   - This includes theme, server changes, components, etc.

2. **Then apply branding modifications**
   - Copy CX-Builder image assets (cxbuilder_empty.svg, cxbuilder_empty_dark.svg, cxbuilder_white.svg, cxbuilder_dark.svg)
   - Apply branded code changes to UI components
   - See CUSTOMIZATION_MANIFEST.json for full file list

3. **Test**
   - Verify all text labels display CX-Builder terminology
   - Verify logos and empty state images render correctly
   - Verify email templates show CX-Builder branding

## Key Modified Files

### Theme & Styling
- `assets/scss/_themes-vars.module.scss` - Brand colors
- `themes/index.js`, `themes/compStyleOverride.js` - Theme overrides
- `ui-component/button/StyledButton.jsx` - Button styling

### Layout & Navigation
- `layout/MainLayout/Header/index.jsx` - Header styling
- `layout/MainLayout/Header/ProfileSection/index.jsx` - Settings menu
- `layout/MainLayout/Sidebar/MenuList/NavItem/index.jsx` - Nav items
- `menu-items/dashboard.js`, `settings.js`, `agentsettings.js` - Menu definitions

### Dialogs
- `ExportAsTemplateDialog.jsx` - Flow type labels
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
