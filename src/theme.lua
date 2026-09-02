local Theme = {}

-- Palette sampled from the Retro Engineering Console SimHub project:
-- graphite surfaces, warm instrument text, amber rules and restrained cyan.
Theme.colors = {
  void = rgbm(0x0B / 255, 0x09 / 255, 0x07 / 255, 0.98),
  surface = rgbm(0x15 / 255, 0x11 / 255, 0x0D / 255, 0.98),
  panel = rgbm(0x0D / 255, 0x0B / 255, 0x09 / 255, 0.98),
  panelRaised = rgbm(0x1A / 255, 0x13 / 255, 0x0E / 255, 0.98),
  metal = rgbm(0x54 / 255, 0x51 / 255, 0x49 / 255, 0.92),
  metalDim = rgbm(0x28 / 255, 0x27 / 255, 0x23 / 255, 0.9),
  outline = rgbm(0x76 / 255, 0x54 / 255, 0x2C / 255, 0.95),
  outlineSoft = rgbm(0x60 / 255, 0x45 / 255, 0x23 / 255, 0.78),
  outlineDim = rgbm(0x33 / 255, 0x25 / 255, 0x19 / 255, 0.9),
  primary = rgbm(0xF2 / 255, 0xDB / 255, 0xAE / 255, 1),
  secondary = rgbm(0x98 / 255, 0x7A / 255, 0x4C / 255, 0.95),
  amber = rgbm(0xFF / 255, 0xC4 / 255, 0x6B / 255, 1),
  amberDim = rgbm(0x5E / 255, 0x43 / 255, 0x19 / 255, 0.92),
  cyan = rgbm(0x68 / 255, 0xB7 / 255, 0xD6 / 255, 1),
  cyanDim = rgbm(0x29 / 255, 0x56 / 255, 0x5C / 255, 0.95),
  shiftBlue = rgbm(0x46 / 255, 0x9B / 255, 0xCA / 255, 1),
  shiftBlueDim = rgbm(0x0D / 255, 0x2C / 255, 0x46 / 255, 1),
  green = rgbm(0x7E / 255, 0xC8 / 255, 0x6A / 255, 1),
  red = rgbm(0xD8 / 255, 0x4B / 255, 0x3E / 255, 1),
  redDim = rgbm(0x52 / 255, 0x1B / 255, 0x18 / 255, 0.92),
  inactive = rgbm(0x2A / 255, 0x21 / 255, 0x17 / 255, 0.92),
  debug = rgbm(0x0B / 255, 0x09 / 255, 0x07 / 255, 0.94)
}

Theme.fonts = {
  utility = 'Consolas;Weight=Regular'
}

function Theme.withAlpha(color, alpha)
  return rgbm(color.r, color.g, color.b, alpha)
end

return Theme
