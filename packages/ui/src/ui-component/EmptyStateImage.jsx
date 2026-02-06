import { useSelector } from 'react-redux'
import IxSuiteEmptyLight from '@/assets/images/ixsuite_empty.svg'
import IxSuiteEmptyDark from '@/assets/images/ixsuite_empty_dark.svg'
import CxBuilderEmptyLight from '@/assets/images/cxbuilder_empty.svg'
import CxBuilderEmptyDark from '@/assets/images/cxbuilder_empty_dark.svg'

/**
 * EmptyStateImage component that shows the appropriate icon
 * based on the current theme (light/dark mode) and brand (ix-suite/cx-builder)
 */
const EmptyStateImage = ({ style, alt = 'No items', ...props }) => {
    const customization = useSelector((state) => state.customization)
    const isDarkMode = customization?.isDarkMode
    const brand = customization?.brand

    const getEmptyImage = () => {
        if (brand === 'cx-builder') {
            return isDarkMode ? CxBuilderEmptyDark : CxBuilderEmptyLight
        }
        return isDarkMode ? IxSuiteEmptyDark : IxSuiteEmptyLight
    }

    const defaultStyle = {
        objectFit: 'cover',
        height: '25vh',
        width: 'auto',
        ...style
    }

    return (
        <img
            style={defaultStyle}
            src={getEmptyImage()}
            alt={alt}
            {...props}
        />
    )
}

export default EmptyStateImage
