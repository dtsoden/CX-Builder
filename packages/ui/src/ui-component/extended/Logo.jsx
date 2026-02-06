// iX-Suite logos
import logo from '@/assets/images/flowise_white.svg'
import logoDark from '@/assets/images/flowise_dark.svg'

// CX-Builder logos
import logoCxBuilder from '@/assets/images/cxbuilder_white.svg'
import logoCxBuilderDark from '@/assets/images/cxbuilder_dark.svg'

import { useSelector } from 'react-redux'

// ==============================|| LOGO ||============================== //

const Logo = () => {
    const customization = useSelector((state) => state.customization)
    const { isDarkMode, brand } = customization

    // Select logo based on brand and dark mode
    const getLogo = () => {
        if (brand === 'cx-builder') {
            return isDarkMode ? logoCxBuilderDark : logoCxBuilder
        }
        return isDarkMode ? logoDark : logo
    }

    const getAltText = () => {
        return brand === 'cx-builder' ? 'CX-Builder' : 'iX Suite'
    }

    return (
        <div style={{ alignItems: 'center', display: 'flex', flexDirection: 'row' }}>
            <img
                style={{ objectFit: 'contain', height: 'auto', width: 150 }}
                src={getLogo()}
                alt={getAltText()}
            />
        </div>
    )
}

export default Logo
