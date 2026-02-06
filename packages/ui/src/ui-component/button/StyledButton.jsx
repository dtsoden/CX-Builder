import { styled } from '@mui/material/styles'
import { Button } from '@mui/material'
import MuiToggleButton from '@mui/material/ToggleButton'

export const StyledButton = styled(Button)(({ theme, color = 'primary' }) => ({
    // Concentrix iX-Suite brand colors
    color: '#003D5B',
    backgroundColor: '#24E2CB',
    '&:hover': {
        backgroundColor: '#fbca1b',
        color: '#003D5B'
    },
    // Override for error buttons (keep red)
    ...(color === 'error' && {
        color: 'white',
        backgroundColor: theme.palette.error.main,
        '&:hover': {
            backgroundColor: theme.palette.error.dark,
            color: 'white'
        }
    })
}))

export const StyledToggleButton = styled(MuiToggleButton)(({ theme, color = 'primary' }) => ({
    '&.Mui-selected, &.Mui-selected:hover': {
        // Concentrix iX-Suite brand colors
        color: '#003D5B',
        backgroundColor: '#24E2CB'
    }
}))
