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
        let hex = hexString.hasPrefix("#") ? hexString.substring(from: hexString.index(hexString.startIndex, offsetBy: 1)) : hexString
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
        
        let rgb = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format:"#%06x", rgb)
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
