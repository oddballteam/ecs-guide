// import adapter from '@sveltejs/adapter-auto'
// import adapter from '@sveltejs/adapter-static'
import adapter from '@sveltejs/adapter-node'
import preprocess from 'svelte-preprocess'
import seqPreprocessor from 'svelte-sequential-preprocessor'
import { preprocessThrelte } from '@threlte/preprocess'

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: seqPreprocessor([preprocess(), preprocessThrelte()]),
	kit: {
		// adapter: adapter()
		adapter: adapter()
	}
	
	// kit: {
  //   adapter: adapter({
  //     fallback: '200.html'
  //   }),
	// 	// trailingSlash: 'always',
  //   prerender: { entries: [] }
  // }
}

export default config;