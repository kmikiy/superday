import UIKit

extension UIColor
{
    //MARK: Initializers
    convenience init(r: Int, g: Int, b: Int, a : CGFloat = 1.0)
    {
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: a)
    }
    
    convenience init(hex: Int)
    {
        self.init(r: (hex >> 16) & 0xff, g: (hex >> 8) & 0xff, b: hex & 0xff)
    }
    
    convenience init(hexString: String)
    {
        let hex = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        var hexInt : UInt32 = 0
        Scanner(string: hex).scanHexInt32(&hexInt)
        
        self.init(hex: Int(hexInt))
    }
    
    var hexString : String
    {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format:"#%02X%02X%02X", Int(r * 0xff), Int(g * 0xff), Int(b * 0xff))
    }
}

extension UIColor
{
    static var familyGreen: UIColor
    {
        return UIColor(r: 40, g: 201, b: 128)
    }
    
    static var almostBlack: UIColor
    {
        return UIColor(r: 4, g: 4, b: 6)
    }
    
    static var normalGray: UIColor
    {
        return UIColor(r: 144, g: 146, b: 147)
    }
    
    static var lightBlue: UIColor
    {
        return UIColor(hex: 0xE6F8FC)
    }
    
    static var lightBlue2: UIColor
    {
        return UIColor(hex: 0xD1F2F9)
    }
}
