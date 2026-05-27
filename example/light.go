components {
  id: "lightsource"
  component: "/lights/lightsource.script"
  properties {
    id: "color"
    value: "0.4, 0.4, 1.0, 1.0"
    type: PROPERTY_TYPE_VECTOR4
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ball_blue_small_alt\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/example/asset/images.atlas\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_DYNAMIC\n"
  "mass: 50.0\n"
  "friction: 0.4\n"
  "restitution: 0.5\n"
  "group: \"ball\"\n"
  "mask: \"block\"\n"
  "mask: \"ball\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 16.0\n"
  "}\n"
  "linear_damping: 0.3\n"
  "locked_rotation: true\n"
  ""
}
