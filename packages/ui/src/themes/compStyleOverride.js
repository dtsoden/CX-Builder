export default function componentStyleOverrides(theme) {
    const bgColor = theme.colors?.grey50
    return {
        MuiCssBaseline: {
            styleOverrides: {
                body: {
                    scrollbarWidth: 'thin',
                    scrollbarColor: theme?.customization?.isDarkMode
                        ? `${theme.colors?.grey500} ${theme.colors?.darkPrimaryMain}`
                        : `${theme.colors?.grey300} ${theme.paper}`,
                    '&::-webkit-scrollbar, & *::-webkit-scrollbar': {
                        width: 12,
                        height: 12,
                        backgroundColor: theme?.customization?.isDarkMode ? theme.colors?.darkPrimaryMain : theme.paper
                    },
                    '&::-webkit-scrollbar-thumb, & *::-webkit-scrollbar-thumb': {
                        borderRadius: 8,
                        backgroundColor: theme?.customization?.isDarkMode ? theme.colors?.grey500 : theme.colors?.grey300,
                        minHeight: 24,
                        border: `3px solid ${theme?.customization?.isDarkMode ? theme.colors?.darkPrimaryMain : theme.paper}`
                    },
                    '&::-webkit-scrollbar-thumb:focus, & *::-webkit-scrollbar-thumb:focus': {
                        backgroundColor: theme?.customization?.isDarkMode ? theme.colors?.darkPrimary200 : theme.colors?.grey500
                    },
                    '&::-webkit-scrollbar-thumb:active, & *::-webkit-scrollbar-thumb:active': {
                        backgroundColor: theme?.customization?.isDarkMode ? theme.colors?.darkPrimary200 : theme.colors?.grey500
                    },
                    '&::-webkit-scrollbar-thumb:hover, & *::-webkit-scrollbar-thumb:hover': {
                        backgroundColor: theme?.customization?.isDarkMode ? theme.colors?.darkPrimary200 : theme.colors?.grey500
                    },
                    '&::-webkit-scrollbar-corner, & *::-webkit-scrollbar-corner': {
                        backgroundColor: theme?.customization?.isDarkMode ? theme.colors?.darkPrimaryMain : theme.paper
                    }
                }
            }
        },
        MuiButton: {
            styleOverrides: {
                root: {
                    fontWeight: 500,
                    borderRadius: '4px'
                },
                // Contained buttons: teal background, dark text - using !important to override sx props
                contained: {
                    backgroundColor: '#24E2CB !important',
                    color: '#003D5B !important',
                    '&:hover': {
                        backgroundColor: '#fbca1b !important',
                        color: '#003D5B !important'
                    }
                },
                containedPrimary: {
                    backgroundColor: '#24E2CB !important',
                    color: '#003D5B !important',
                    '&:hover': {
                        backgroundColor: '#fbca1b !important',
                        color: '#003D5B !important'
                    }
                },
                containedSecondary: {
                    backgroundColor: '#24E2CB !important',
                    color: '#003D5B !important',
                    '&:hover': {
                        backgroundColor: '#fbca1b !important',
                        color: '#003D5B !important'
                    }
                },
                // Text buttons: primary color text (teal in dark mode for visibility)
                text: {
                    color: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important',
                    '&:hover': {
                        backgroundColor: theme?.customization?.isDarkMode ? 'rgba(251, 202, 27, 0.2) !important' : 'rgba(36, 226, 203, 0.1) !important',
                        color: '#fbca1b !important'
                    }
                },
                textPrimary: {
                    color: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important',
                    '&:hover': {
                        backgroundColor: theme?.customization?.isDarkMode ? 'rgba(251, 202, 27, 0.2) !important' : 'rgba(36, 226, 203, 0.1) !important',
                        color: '#fbca1b !important'
                    }
                },
                // Outlined buttons: teal border/text in dark mode for visibility
                outlined: {
                    borderColor: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important',
                    color: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important',
                    '&:hover': {
                        borderColor: '#fbca1b !important',
                        backgroundColor: theme?.customization?.isDarkMode ? 'rgba(251, 202, 27, 0.2) !important' : 'rgba(36, 226, 203, 0.1) !important',
                        color: '#fbca1b !important'
                    }
                },
                outlinedPrimary: {
                    borderColor: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important',
                    color: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important',
                    '&:hover': {
                        borderColor: '#fbca1b !important',
                        backgroundColor: theme?.customization?.isDarkMode ? 'rgba(251, 202, 27, 0.2) !important' : 'rgba(36, 226, 203, 0.1) !important',
                        color: '#fbca1b !important'
                    }
                }
            }
        },
        MuiPaper: {
            defaultProps: {
                elevation: 0
            },
            styleOverrides: {
                root: {
                    backgroundImage: 'none'
                },
                rounded: {
                    borderRadius: `${theme?.customization?.borderRadius}px`
                }
            }
        },
        MuiCardHeader: {
            styleOverrides: {
                root: {
                    color: theme.colors?.textDark,
                    padding: '24px'
                },
                title: {
                    fontSize: '1.125rem'
                }
            }
        },
        MuiCardContent: {
            styleOverrides: {
                root: {
                    padding: '24px'
                }
            }
        },
        MuiCardActions: {
            styleOverrides: {
                root: {
                    padding: '24px'
                }
            }
        },
        MuiListItemButton: {
            styleOverrides: {
                root: {
                    color: theme.darkTextPrimary,
                    paddingTop: '10px',
                    paddingBottom: '10px',
                    '&.Mui-selected': {
                        color: theme.menuSelected,
                        backgroundColor: theme.menuSelectedBack,
                        '&:hover': {
                            // Concentrix iX-Suite hover color
                            backgroundColor: '#fbca1b'
                        },
                        '& .MuiListItemIcon-root': {
                            color: theme.menuSelected
                        }
                    },
                    '&:hover': {
                        // Concentrix iX-Suite hover color
                        backgroundColor: '#fbca1b',
                        color: theme.menuSelected,
                        '& .MuiListItemIcon-root': {
                            color: theme.menuSelected
                        }
                    }
                }
            }
        },
        MuiListItemIcon: {
            styleOverrides: {
                root: {
                    color: theme.darkTextPrimary,
                    minWidth: '36px'
                }
            }
        },
        MuiListItemText: {
            styleOverrides: {
                primary: {
                    color: theme.textDark
                }
            }
        },
        MuiInputBase: {
            styleOverrides: {
                input: {
                    color: theme.textDark,
                    '&::placeholder': {
                        color: theme.darkTextSecondary,
                        fontSize: '0.875rem'
                    },
                    '&.Mui-disabled': {
                        WebkitTextFillColor: theme?.customization?.isDarkMode ? theme.colors?.grey500 : theme.darkTextSecondary
                    }
                }
            }
        },
        MuiOutlinedInput: {
            styleOverrides: {
                root: {
                    background: theme?.customization?.isDarkMode ? theme.colors?.darkPrimary800 : bgColor,
                    borderRadius: `${theme?.customization?.borderRadius}px`,
                    '& .MuiOutlinedInput-notchedOutline': {
                        borderColor: theme?.customization?.isDarkMode ? 'rgba(255, 255, 255, 0.23)' : theme.colors?.grey400
                    },
                    '&:hover .MuiOutlinedInput-notchedOutline': {
                        borderColor: theme?.customization?.isDarkMode ? '#24E2CB' : theme.colors?.primaryLight
                    },
                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                        borderColor: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important'
                    },
                    '&.MuiInputBase-multiline': {
                        padding: 1
                    }
                },
                input: {
                    fontWeight: 500,
                    background: theme?.customization?.isDarkMode ? theme.colors?.darkPrimary800 : bgColor,
                    padding: '15.5px 14px',
                    borderRadius: `${theme?.customization?.borderRadius}px`,
                    '&.MuiInputBase-inputSizeSmall': {
                        padding: '10px 14px',
                        '&.MuiInputBase-inputAdornedStart': {
                            paddingLeft: 0
                        }
                    }
                },
                inputAdornedStart: {
                    paddingLeft: 4
                },
                notchedOutline: {
                    borderRadius: `${theme?.customization?.borderRadius}px`
                }
            }
        },
        MuiSlider: {
            styleOverrides: {
                root: {
                    '&.Mui-disabled': {
                        color: theme.colors?.grey300
                    }
                },
                mark: {
                    backgroundColor: theme.paper,
                    width: '4px'
                },
                valueLabel: {
                    color: theme?.colors?.primaryLight
                }
            }
        },
        MuiDivider: {
            styleOverrides: {
                root: {
                    borderColor: theme.divider,
                    opacity: 1
                }
            }
        },
        MuiAvatar: {
            styleOverrides: {
                root: {
                    color: theme.colors?.primaryDark,
                    background: theme.colors?.primary200
                }
            }
        },
        MuiChip: {
            styleOverrides: {
                root: {
                    '&.MuiChip-deletable .MuiChip-deleteIcon': {
                        color: 'inherit'
                    }
                },
                // Filled primary chips: gold in dark mode for contrast, teal in light mode
                filledPrimary: {
                    backgroundColor: theme?.customization?.isDarkMode ? '#fbca1b' : '#24E2CB',
                    color: '#003D5B',
                    '& .MuiChip-label': {
                        color: '#003D5B'
                    },
                    // When parent (toggle button) is hovered, switch to teal so it contrasts with gold hover bg
                    '.MuiToggleButton-root:hover &, .MuiButtonBase-root:hover &': {
                        backgroundColor: '#24E2CB'
                    }
                },
                // Outlined chips in dark mode need teal border/text
                outlinedPrimary: {
                    borderColor: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B',
                    color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B'
                }
            }
        },
        MuiTooltip: {
            styleOverrides: {
                tooltip: {
                    color: theme?.customization?.isDarkMode ? theme.colors?.paper : theme.paper,
                    background: theme.colors?.grey700
                }
            }
        },
        MuiIconButton: {
            styleOverrides: {
                root: {
                    // Teal in dark mode for visibility, navy in light mode
                    color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B',
                    '&:hover': {
                        backgroundColor: '#fbca1b',
                        color: '#003D5B'
                    }
                },
                colorPrimary: {
                    color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B',
                    '&:hover': {
                        backgroundColor: '#fbca1b',
                        color: '#003D5B'
                    }
                },
                colorSecondary: {
                    color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B',
                    '&:hover': {
                        backgroundColor: '#fbca1b',
                        color: '#003D5B'
                    }
                }
            }
        },
        MuiToggleButton: {
            styleOverrides: {
                root: {
                    // Unselected: teal text in dark mode, navy in light mode
                    color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B',
                    borderColor: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B',
                    '&.Mui-selected': {
                        // Selected: teal background, navy text
                        backgroundColor: '#24E2CB',
                        color: '#003D5B',
                        '&:hover': {
                            backgroundColor: '#fbca1b',
                            color: '#003D5B'
                        }
                    },
                    '&:hover': {
                        backgroundColor: theme?.customization?.isDarkMode ? 'rgba(36, 226, 203, 0.2)' : 'rgba(0, 61, 91, 0.1)'
                    }
                }
            }
        },
        MuiLoadingButton: {
            styleOverrides: {
                root: {
                    backgroundColor: '#24E2CB !important',
                    color: '#003D5B !important',
                    '&:hover': {
                        backgroundColor: '#fbca1b !important',
                        color: '#003D5B !important'
                    },
                    '& .MuiLoadingButton-loadingIndicator': {
                        color: '#003D5B'
                    }
                }
            }
        },
        MuiFab: {
            styleOverrides: {
                root: {
                    backgroundColor: '#24E2CB',
                    color: '#003D5B',
                    '&:hover': {
                        backgroundColor: '#fbca1b'
                    }
                },
                primary: {
                    backgroundColor: '#24E2CB',
                    color: '#003D5B',
                    '&:hover': {
                        backgroundColor: '#fbca1b'
                    }
                },
                secondary: {
                    backgroundColor: '#24E2CB',
                    color: '#003D5B',
                    '&:hover': {
                        backgroundColor: '#fbca1b'
                    }
                }
            }
        },
        MuiCircularProgress: {
            styleOverrides: {
                root: {
                    // Gold spinner for visibility in dark mode
                    color: '#fbca1b'
                },
                colorPrimary: {
                    color: '#fbca1b'
                },
                colorSecondary: {
                    color: '#fbca1b'
                },
                colorInherit: {
                    color: '#fbca1b'
                }
            }
        },
        // Tabs: teal indicator in dark mode for visibility
        MuiTabs: {
            styleOverrides: {
                indicator: {
                    backgroundColor: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B'
                }
            }
        },
        // Tab: teal selected text in dark mode for visibility
        MuiTab: {
            styleOverrides: {
                root: {
                    color: theme?.customization?.isDarkMode ? 'rgba(255, 255, 255, 0.7)' : 'inherit',
                    '&.Mui-selected': {
                        color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B'
                    }
                }
            }
        },
        // Select: teal focus border in dark mode
        MuiSelect: {
            styleOverrides: {
                root: {
                    '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
                        borderColor: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important'
                    }
                }
            }
        },
        // TextField: teal focus border in dark mode
        MuiTextField: {
            styleOverrides: {
                root: {
                    '& .MuiOutlinedInput-root.Mui-focused .MuiOutlinedInput-notchedOutline': {
                        borderColor: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important'
                    },
                    '& .MuiInputLabel-root.Mui-focused': {
                        color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B'
                    }
                }
            }
        },
        // InputLabel: teal focus color in dark mode
        MuiInputLabel: {
            styleOverrides: {
                root: {
                    '&.Mui-focused': {
                        color: theme?.customization?.isDarkMode ? '#24E2CB' : '#003D5B'
                    }
                }
            }
        },
        // Autocomplete: teal focus styling in dark mode
        MuiAutocomplete: {
            styleOverrides: {
                root: {
                    '& .MuiOutlinedInput-root.Mui-focused .MuiOutlinedInput-notchedOutline': {
                        borderColor: theme?.customization?.isDarkMode ? '#24E2CB !important' : '#003D5B !important'
                    }
                },
                option: {
                    '&:hover': {
                        background: theme?.customization?.isDarkMode ? '#233345 !important' : ''
                    }
                }
            }
        }
    }
}
