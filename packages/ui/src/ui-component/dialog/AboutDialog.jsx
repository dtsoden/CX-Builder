import { createPortal } from 'react-dom'
import { useState, useEffect } from 'react'
import PropTypes from 'prop-types'
import { Dialog, DialogContent, DialogTitle, Typography, Box } from '@mui/material'
import axios from 'axios'
import { baseURL } from '@/store/constant'

const AboutDialog = ({ show, onCancel }) => {
    const portalElement = document.getElementById('portal')

    const [currentVersion, setCurrentVersion] = useState('')

    useEffect(() => {
        if (show) {
            axios.get(`${baseURL}/api/v1/version`, {
                withCredentials: true,
                headers: { 'Content-type': 'application/json', 'x-request-from': 'internal' }
            })
                .then((response) => {
                    setCurrentVersion(response.data.version)
                })
                .catch((error) => {
                    console.error('Error fetching version:', error)
                })
        }
    }, [show])

    const component = show ? (
        <Dialog
            onClose={onCancel}
            open={show}
            fullWidth
            maxWidth='xs'
            aria-labelledby='alert-dialog-title'
            aria-describedby='alert-dialog-description'
        >
            <DialogTitle sx={{ fontSize: '1rem' }} id='alert-dialog-title'>
                iX-Suite Version
            </DialogTitle>
            <DialogContent>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, py: 1 }}>
                    <Typography variant='body1' fontWeight={500}>Current Version:</Typography>
                    <Typography variant='body1'>{currentVersion}</Typography>
                </Box>
            </DialogContent>
        </Dialog>
    ) : null

    return createPortal(component, portalElement)
}

AboutDialog.propTypes = {
    show: PropTypes.bool,
    onCancel: PropTypes.func
}

export default AboutDialog
