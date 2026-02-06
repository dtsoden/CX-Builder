import { useSelector } from 'react-redux'
import CxBuilderEmptyLight from '@/assets/images/cxbuilder_empty.svg'
import CxBuilderEmptyDark from '@/assets/images/cxbuilder_empty_dark.svg'

/**
 * EmptyStateImage component that shows the appropriate icon
 * based on the current theme (light/dark mode)
 */
const EmptyStateImage = ({ style, alt = 'No items', ...props }) => {
    const customization = useSelector((state) => state.customization)
    const isDarkMode = customization?.isDarkMode

    const defaultStyle = {
        objectFit: 'cover',
        height: '25vh',
        width: 'auto',
        ...style
    }

    return (
        <img
            style={defaultStyle}
            src={isDarkMode ? CxBuilderEmptyDark : CxBuilderEmptyLight}
            alt={alt}
            {...props}
        />
    )
}

export default EmptyStateImage
