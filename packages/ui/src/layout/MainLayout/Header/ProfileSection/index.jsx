import PropTypes from 'prop-types'
import { useEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { useDispatch, useSelector } from 'react-redux'
import { useNavigate } from 'react-router-dom'

import { closeSnackbar as closeSnackbarAction, enqueueSnackbar as enqueueSnackbarAction, REMOVE_DIRTY, SET_BRAND } from '@/store/actions'
import { exportData, stringify } from '@/utils/exportImport'
import useNotifier from '@/utils/useNotifier'

// material-ui
import {
    Avatar,
    Box,
    Button,
    ButtonBase,
    Checkbox,
    ClickAwayListener,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Divider,
    FormControlLabel,
    List,
    ListItemButton,
    ListItemIcon,
    ListItemText,
    Paper,
    Popper,
    Stack,
    Switch,
    Typography
} from '@mui/material'
import { useTheme } from '@mui/material/styles'

// third-party
import PerfectScrollbar from 'react-perfect-scrollbar'

// project imports
import { PermissionListItemButton } from '@/ui-component/button/RBACButtons'
import MainCard from '@/ui-component/cards/MainCard'
import AboutDialog from '@/ui-component/dialog/AboutDialog'
import Transitions from '@/ui-component/extended/Transitions'

// assets
import ExportingGIF from '@/assets/images/Exporting.gif'
import { IconFileExport, IconFileUpload, IconInfoCircle, IconLogout, IconPalette, IconSettings, IconUserEdit, IconX } from '@tabler/icons-react'
import './index.css'

// API
import exportImportApi from '@/api/exportimport'

// Hooks
import useApi from '@/hooks/useApi'
import { getErrorMessage } from '@/utils/errorHandler'

// Data export items with both brand labels
const dataExportItems = [
    { key: 'agentflow', ixLabel: 'iX-Hero', cxLabel: 'Agentflows' },
    { key: 'agentflowv2', ixLabel: 'iX-Hero V2', cxLabel: 'Agentflows V2' },
    { key: 'assistantCustom', ixLabel: 'Assistants Custom', cxLabel: 'Assistants Custom' },
    { key: 'assistantOpenAI', ixLabel: 'Assistants OpenAI', cxLabel: 'Assistants OpenAI' },
    { key: 'assistantAzure', ixLabel: 'Assistants Azure', cxLabel: 'Assistants Azure' },
    { key: 'chatflow', ixLabel: 'iX-Hello', cxLabel: 'Chatflows' },
    { key: 'chat_message', ixLabel: 'Chat Messages', cxLabel: 'Chat Messages' },
    { key: 'chat_feedback', ixLabel: 'Chat Feedbacks', cxLabel: 'Chat Feedbacks' },
    { key: 'custom_template', ixLabel: 'Custom Templates', cxLabel: 'Custom Templates' },
    { key: 'document_store', ixLabel: 'iX-Wisdom', cxLabel: 'Document Stores' },
    { key: 'execution', ixLabel: 'Executions', cxLabel: 'Executions' },
    { key: 'tool', ixLabel: 'Tools', cxLabel: 'Tools' },
    { key: 'variable', ixLabel: 'Variables', cxLabel: 'Variables' }
]

// Get labels based on brand
const getDataLabels = (brand) => dataExportItems.map(item =>
    brand === 'cx-builder' ? item.cxLabel : item.ixLabel
)

// Map label back to key for export
const labelToKey = (label, brand) => {
    const item = dataExportItems.find(i =>
        (brand === 'cx-builder' ? i.cxLabel : i.ixLabel) === label
    )
    return item?.key
}

const ExportDialog = ({ show, onCancel, onExport, brand }) => {
    const portalElement = document.getElementById('portal')
    const dataToExport = getDataLabels(brand)

    const [selectedData, setSelectedData] = useState(dataToExport)
    const [isExporting, setIsExporting] = useState(false)

    useEffect(() => {
        if (show) {
            setIsExporting(false)
            setSelectedData(dataToExport) // Reset selection when dialog opens
        }

        return () => {
            setIsExporting(false)
        }

        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [show, brand])

    const component = show ? (
        <Dialog
            onClose={!isExporting ? onCancel : undefined}
            open={show}
            fullWidth
            maxWidth='sm'
            aria-labelledby='export-dialog-title'
            aria-describedby='export-dialog-description'
        >
            <DialogTitle sx={{ fontSize: '1rem' }} id='export-dialog-title'>
                {!isExporting ? 'Select Data to Export' : 'Exporting..'}
            </DialogTitle>
            <DialogContent>
                {!isExporting && (
                    <Stack
                        direction='row'
                        sx={{
                            display: 'grid',
                            gridTemplateColumns: 'repeat(2, 1fr)',
                            gap: 1
                        }}
                    >
                        {dataToExport.map((data, index) => (
                            <FormControlLabel
                                key={index}
                                size='small'
                                control={
                                    <Checkbox
                                        color='success'
                                        checked={selectedData.includes(data)}
                                        onChange={(event) => {
                                            setSelectedData(
                                                event.target.checked
                                                    ? [...selectedData, data]
                                                    : selectedData.filter((item) => item !== data)
                                            )
                                        }}
                                    />
                                }
                                label={data}
                            />
                        ))}
                    </Stack>
                )}
                {isExporting && (
                    <Box sx={{ height: 'auto', display: 'flex', justifyContent: 'center', mb: 3 }}>
                        <div style={{ display: 'flex', flexDirection: 'column' }}>
                            <img
                                style={{
                                    objectFit: 'cover',
                                    height: 'auto',
                                    width: 'auto'
                                }}
                                src={ExportingGIF}
                                alt='ExportingGIF'
                            />
                            <span>Exporting data might takes a while</span>
                        </div>
                    </Box>
                )}
            </DialogContent>
            {!isExporting && (
                <DialogActions>
                    <Button onClick={onCancel}>Cancel</Button>
                    <Button
                        disabled={selectedData.length === 0}
                        variant='contained'
                        onClick={() => {
                            setIsExporting(true)
                            onExport(selectedData)
                        }}
                    >
                        Export
                    </Button>
                </DialogActions>
            )}
        </Dialog>
    ) : null

    return createPortal(component, portalElement)
}

ExportDialog.propTypes = {
    show: PropTypes.bool,
    onCancel: PropTypes.func,
    onExport: PropTypes.func,
    brand: PropTypes.string
}

const ImportDialog = ({ show }) => {
    const portalElement = document.getElementById('portal')

    const component = show ? (
        <Dialog open={show} fullWidth maxWidth='sm' aria-labelledby='import-dialog-title' aria-describedby='import-dialog-description'>
            <DialogTitle sx={{ fontSize: '1rem' }} id='import-dialog-title'>
                Importing...
            </DialogTitle>
            <DialogContent>
                <Box sx={{ height: 'auto', display: 'flex', justifyContent: 'center', mb: 3 }}>
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                        <img
                            style={{
                                objectFit: 'cover',
                                height: 'auto',
                                width: 'auto'
                            }}
                            src={ExportingGIF}
                            alt='ImportingGIF'
                        />
                        <span>Importing data might takes a while</span>
                    </div>
                </Box>
            </DialogContent>
        </Dialog>
    ) : null

    return createPortal(component, portalElement)
}

ImportDialog.propTypes = {
    show: PropTypes.bool
}

// ==============================|| PROFILE MENU ||============================== //

const ProfileSection = ({ handleLogout }) => {
    const theme = useTheme()

    const customization = useSelector((state) => state.customization)
    const brand = customization.brand || 'ix-suite'

    const [open, setOpen] = useState(false)
    const [aboutDialogOpen, setAboutDialogOpen] = useState(false)

    const [exportDialogOpen, setExportDialogOpen] = useState(false)
    const [importDialogOpen, setImportDialogOpen] = useState(false)

    const anchorRef = useRef(null)
    const inputRef = useRef()

    const navigate = useNavigate()
    const currentUser = useSelector((state) => state.auth.user)
    const isAuthenticated = useSelector((state) => state.auth.isAuthenticated)

    const importAllApi = useApi(exportImportApi.importData)
    const exportAllApi = useApi(exportImportApi.exportData)
    const prevOpen = useRef(open)

    // ==============================|| Snackbar ||============================== //

    useNotifier()
    const dispatch = useDispatch()
    const enqueueSnackbar = (...args) => dispatch(enqueueSnackbarAction(...args))
    const closeSnackbar = (...args) => dispatch(closeSnackbarAction(...args))

    // Update document title and favicon when brand changes
    useEffect(() => {
        document.title = brand === 'cx-builder' ? 'CX-Builder\u2122' : 'Concentrix iX-Suite'

        // Update favicons based on brand (light/dark handled by media queries on the link elements)
        const faviconLight = document.getElementById('favicon-light')
        const faviconDark = document.getElementById('favicon-dark')
        if (brand === 'cx-builder') {
            if (faviconLight) faviconLight.href = '/cx-icon.png'
            if (faviconDark) faviconDark.href = '/cx-icon-dark.png'
        } else {
            if (faviconLight) faviconLight.href = '/ix-icon.png'
            if (faviconDark) faviconDark.href = '/ix-icon-dark.png'
        }
    }, [brand])

    const handleBrandToggle = () => {
        const newBrand = brand === 'ix-suite' ? 'cx-builder' : 'ix-suite'
        localStorage.setItem('appBrand', newBrand)
        dispatch({ type: SET_BRAND, brand: newBrand })
    }

    const handleClose = (event) => {
        if (anchorRef.current && anchorRef.current.contains(event.target)) {
            return
        }
        setOpen(false)
    }

    const handleToggle = () => {
        setOpen((prevOpen) => !prevOpen)
    }

    const errorFailed = (message) => {
        enqueueSnackbar({
            message: message,
            options: {
                key: new Date().getTime() + Math.random(),
                variant: 'error',
                persist: true,
                action: (key) => (
                    <Button style={{ color: 'white' }} onClick={() => closeSnackbar(key)}>
                        <IconX />
                    </Button>
                )
            }
        })
    }

    const fileChange = (e) => {
        if (!e.target.files) return

        const file = e.target.files[0]
        setImportDialogOpen(true)

        const reader = new FileReader()
        reader.onload = (evt) => {
            if (!evt?.target?.result) {
                return
            }
            const body = JSON.parse(evt.target.result)
            importAllApi.request(body)
        }
        reader.readAsText(file)
    }

    const importAllSuccess = () => {
        setImportDialogOpen(false)
        dispatch({ type: REMOVE_DIRTY })
        enqueueSnackbar({
            message: `Import All successful`,
            options: {
                key: new Date().getTime() + Math.random(),
                variant: 'success',
                action: (key) => (
                    <Button style={{ color: 'white' }} onClick={() => closeSnackbar(key)}>
                        <IconX />
                    </Button>
                )
            }
        })
    }

    const importAll = () => {
        inputRef.current.click()
    }

    const onExport = (selectedLabels) => {
        const body = {}
        // Convert selected labels to API keys using the brand-aware mapping
        selectedLabels.forEach(label => {
            const key = labelToKey(label, brand)
            if (key) body[key] = true
        })

        exportAllApi.request(body)
    }

    useEffect(() => {
        if (importAllApi.data) {
            importAllSuccess()
            navigate(0)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [importAllApi.data])

    useEffect(() => {
        if (importAllApi.error) {
            setImportDialogOpen(false)
            let errMsg = 'Invalid Imported File'
            let error = importAllApi.error
            if (error?.response?.data) {
                errMsg = typeof error.response.data === 'object' ? error.response.data.message : error.response.data
            }
            errorFailed(`Failed to import: ${errMsg}`)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [importAllApi.error])

    useEffect(() => {
        if (exportAllApi.data) {
            setExportDialogOpen(false)
            try {
                const dataStr = stringify(exportData(exportAllApi.data))
                //const dataUri = 'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr)
                const blob = new Blob([dataStr], { type: 'application/json' })
                const dataUri = URL.createObjectURL(blob)

                const linkElement = document.createElement('a')
                linkElement.setAttribute('href', dataUri)
                linkElement.setAttribute('download', exportAllApi.data.FileDefaultName)
                linkElement.click()
            } catch (error) {
                errorFailed(`Failed to export all: ${getErrorMessage(error)}`)
            }
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [exportAllApi.data])

    useEffect(() => {
        if (exportAllApi.error) {
            setExportDialogOpen(false)
            let errMsg = 'Internal Server Error'
            let error = exportAllApi.error
            if (error?.response?.data) {
                errMsg = typeof error.response.data === 'object' ? error.response.data.message : error.response.data
            }
            errorFailed(`Failed to export: ${errMsg}`)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [exportAllApi.error])

    useEffect(() => {
        if (prevOpen.current === true && open === false) {
            anchorRef.current.focus()
        }
        prevOpen.current = open
    }, [open])

    return (
        <>
            <ButtonBase ref={anchorRef} sx={{ borderRadius: '12px', overflow: 'hidden' }}>
                <Avatar
                    variant='rounded'
                    sx={{
                        ...theme.typography.commonAvatar,
                        ...theme.typography.mediumAvatar,
                        transition: 'all .2s ease-in-out',
                        // Concentrix iX-Suite brand colors
                        background: '#24E2CB',
                        color: '#003D5B',
                        '&:hover': {
                            background: '#fbca1b',
                            color: '#003D5B'
                        }
                    }}
                    onClick={handleToggle}
                    color='inherit'
                >
                    <IconSettings stroke={1.5} size='1.3rem' />
                </Avatar>
            </ButtonBase>
            <Popper
                placement='bottom-end'
                open={open}
                anchorEl={anchorRef.current}
                role={undefined}
                transition
                disablePortal
                popperOptions={{
                    modifiers: [
                        {
                            name: 'offset',
                            options: {
                                offset: [0, 14]
                            }
                        }
                    ]
                }}
            >
                {({ TransitionProps }) => (
                    <Transitions in={open} {...TransitionProps}>
                        <Paper>
                            <ClickAwayListener onClickAway={handleClose}>
                                <MainCard border={false} elevation={16} content={false} boxShadow shadow={theme.shadows[16]}>
                                    {isAuthenticated && currentUser ? (
                                        <Box sx={{ p: 2 }}>
                                            <Typography component='span' variant='h4'>
                                                {currentUser.name}
                                            </Typography>
                                        </Box>
                                    ) : (
                                        <Box sx={{ p: 2 }}>
                                            <Typography component='span' variant='h4'>
                                                User
                                            </Typography>
                                        </Box>
                                    )}
                                    <PerfectScrollbar style={{ height: '100%', maxHeight: 'calc(100vh - 250px)', overflowX: 'hidden' }}>
                                        <Box sx={{ p: 2 }}>
                                            <Divider />
                                            <List
                                                component='nav'
                                                sx={{
                                                    width: '100%',
                                                    maxWidth: 250,
                                                    minWidth: 200,
                                                    backgroundColor: theme.palette.background.paper,
                                                    borderRadius: '10px',
                                                    [theme.breakpoints.down('md')]: {
                                                        minWidth: '100%'
                                                    },
                                                    '& .MuiListItemButton-root': {
                                                        mt: 0.5
                                                    }
                                                }}
                                            >
                                                <PermissionListItemButton
                                                    permissionId='workspace:export'
                                                    sx={{ borderRadius: `${customization.borderRadius}px` }}
                                                    onClick={() => {
                                                        setExportDialogOpen(true)
                                                    }}
                                                >
                                                    <ListItemIcon>
                                                        <IconFileExport stroke={1.5} size='1.3rem' />
                                                    </ListItemIcon>
                                                    <ListItemText primary={<Typography variant='body2'>Export</Typography>} />
                                                </PermissionListItemButton>
                                                <PermissionListItemButton
                                                    permissionId='workspace:import'
                                                    sx={{ borderRadius: `${customization.borderRadius}px` }}
                                                    onClick={() => {
                                                        importAll()
                                                    }}
                                                >
                                                    <ListItemIcon>
                                                        <IconFileUpload stroke={1.5} size='1.3rem' />
                                                    </ListItemIcon>
                                                    <ListItemText primary={<Typography variant='body2'>Import</Typography>} />
                                                </PermissionListItemButton>
                                                <input ref={inputRef} type='file' hidden onChange={fileChange} accept='.json' />
                                                {window.__IX_STUDIO__ === '1' && (
                                                    <>
                                                        <Divider sx={{ my: 1 }} />
                                                        <ListItemButton
                                                            sx={{ borderRadius: `${customization.borderRadius}px` }}
                                                            onClick={handleBrandToggle}
                                                        >
                                                            <ListItemIcon>
                                                                <IconPalette stroke={1.5} size='1.3rem' />
                                                            </ListItemIcon>
                                                            <ListItemText
                                                                primary={
                                                                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                                                                        <Typography variant='body2'>CX-Builder Mode</Typography>
                                                                        <Switch
                                                                            size='small'
                                                                            checked={brand === 'cx-builder'}
                                                                            onChange={handleBrandToggle}
                                                                            onClick={(e) => e.stopPropagation()}
                                                                            sx={{
                                                                                '& .MuiSwitch-switchBase.Mui-checked': {
                                                                                    color: '#24E2CB',
                                                                                },
                                                                                '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                                                                                    backgroundColor: '#24E2CB',
                                                                                },
                                                                            }}
                                                                        />
                                                                    </Box>
                                                                }
                                                            />
                                                        </ListItemButton>
                                                    </>
                                                )}
                                                <Divider sx={{ my: 1 }} />
                                                <ListItemButton
                                                    sx={{ borderRadius: `${customization.borderRadius}px` }}
                                                    onClick={() => {
                                                        setOpen(false)
                                                        setAboutDialogOpen(true)
                                                    }}
                                                >
                                                    <ListItemIcon>
                                                        <IconInfoCircle stroke={1.5} size='1.3rem' />
                                                    </ListItemIcon>
                                                    <ListItemText primary={<Typography variant='body2'>Version</Typography>} />
                                                </ListItemButton>
                                                {isAuthenticated && !currentUser.isSSO && (
                                                    <ListItemButton
                                                        sx={{ borderRadius: `${customization.borderRadius}px` }}
                                                        onClick={() => {
                                                            setOpen(false)
                                                            navigate('/account')
                                                        }}
                                                    >
                                                        <ListItemIcon>
                                                            <IconUserEdit stroke={1.5} size='1.3rem' />
                                                        </ListItemIcon>
                                                        <ListItemText primary={<Typography variant='body2'>Account Settings</Typography>} />
                                                    </ListItemButton>
                                                )}
                                                <ListItemButton
                                                    sx={{ borderRadius: `${customization.borderRadius}px` }}
                                                    onClick={handleLogout}
                                                >
                                                    <ListItemIcon>
                                                        <IconLogout stroke={1.5} size='1.3rem' />
                                                    </ListItemIcon>
                                                    <ListItemText primary={<Typography variant='body2'>Logout</Typography>} />
                                                </ListItemButton>
                                            </List>
                                        </Box>
                                    </PerfectScrollbar>
                                </MainCard>
                            </ClickAwayListener>
                        </Paper>
                    </Transitions>
                )}
            </Popper>
            <AboutDialog show={aboutDialogOpen} onCancel={() => setAboutDialogOpen(false)} />
            <ExportDialog show={exportDialogOpen} onCancel={() => setExportDialogOpen(false)} onExport={(data) => onExport(data)} brand={brand} />
            <ImportDialog show={importDialogOpen} />
        </>
    )
}

ProfileSection.propTypes = {
    handleLogout: PropTypes.func
}

export default ProfileSection
