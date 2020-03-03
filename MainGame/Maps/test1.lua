return {
  version = "1.2",
  luaversion = "5.1",
  tiledversion = "1.3.2",
  orientation = "orthogonal",
  renderorder = "left-up",
  width = 10,
  height = 10,
  tilewidth = 32,
  tileheight = 32,
  nextlayerid = 5,
  nextobjectid = 1,
  properties = {},
  tilesets = {
    {
      name = "generic_platformer_tiles",
      firstgid = 1,
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 32,
      image = "generic_platformer_tiles.png",
      imagewidth = 1024,
      imageheight = 768,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      terrains = {},
      tilecount = 768,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      id = 3,
      name = "Background",
      x = 0,
      y = 0,
      width = 10,
      height = 10,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143,
        143, 143, 143, 143, 143, 143, 143, 143, 143, 143
      }
    },
    {
      type = "tilelayer",
      id = 1,
      name = "plats",
      x = 0,
      y = 0,
      width = 10,
      height = 10,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        183, 184, 185, 186, 187, 188, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 156, 0, 0,
        0, 0, 0, 0, 183, 184, 185, 186, 187, 188,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 183, 184, 185, 186, 187, 188, 0, 0, 0
      }
    },
    {
      type = "tilelayer",
      id = 4,
      name = "spawn",
      x = 0,
      y = 0,
      width = 10,
      height = 10,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 566, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    }
  }
}
