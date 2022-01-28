components {
  id: "block_l"
  component: "/example/block_l.tilemap"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "collision_shape: \"/example/block_l.tilemap\"\n"
  "type: COLLISION_OBJECT_TYPE_DYNAMIC\n"
  "mass: 500.0\n"
  "friction: 0.9\n"
  "restitution: 0.5\n"
  "group: \"default\"\n"
  "mask: \"block\"\n"
  "mask: \"ball\"\n"
  "linear_damping: 0.5\n"
  "angular_damping: 0.7\n"
  "locked_rotation: false\n"
  "bullet: false\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
