import logoCxBuilder from '@/assets/images/cxbuilder_white.svg'
import logoCxBuilderDark from '@/assets/images/cxbuilder_dark.svg'

import { useSelector } from 'react-redux'

// ==============================|| LOGO ||============================== //

const Logo = () => {
    const customization = useSelector((state) => state.customization)
    const { isDarkMode } = customization

    return (
        <div style={{ alignItems: 'center', display: 'flex', flexDirection: 'row' }}>
            <img
                style={{ objectFit: 'contain', height: 'auto', width: 150 }}
                src={isDarkMode ? logoCxBuilderDark : logoCxBuilder}
                alt='CX-Builder'
            />
        </div>
    )
}

export default Logo
