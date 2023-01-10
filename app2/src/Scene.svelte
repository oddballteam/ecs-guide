<script>
	import { OrbitControls, PerspectiveCamera, AmbientLight, useFrame } from '@threlte/core'
	import { GLTF, Environment } from '@threlte/extras'
	import { spring } from 'svelte/motion'

	const scale = spring(.5)
	let rotation = 0

	useFrame(() => {
		rotation += 0.0005
	})
</script>

<Environment
  path = '/'
  files='beach.hdr'
  isBackground={true}
  format="hdr"
  groundProjection={{ radius: 200, height: 5, scale: {x: 100,y: 100,z: 100} }}
/>

<PerspectiveCamera position={{ x: 5, y: 5, z: 5 }} fov={65}>
  <OrbitControls autoRotate enableDamping autoRotateSpeed=.3 />
</PerspectiveCamera>

<AmbientLight />

<GLTF
  url="/cms.gltf"
  interactive
  castShadow 
  receiveShadow 
  rotation={{ x: 0, y: rotation, z: 0 }}
  scale={$scale}
  position={{ y: 1 }}
  on:pointerenter={() => ($scale = .6)}
  on:pointerleave={() => ($scale = .5)}
/>
  
