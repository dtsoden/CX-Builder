import { styled } from '@mui/material/styles'
import { Fab } from '@mui/material'

export const StyledFab = styled(Fab)(({ theme, color = 'primary' }) => ({
    color: '#003D5B',
    backgroundColor: '#24E2CB',
    '&:hover': {
        backgroundColor: '#fbca1b',
        color: '#003D5B'
    }
}))
