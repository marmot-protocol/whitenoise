Pod::Spec.new do |s|
  s.name = 'rust_lib_whitenoise_nse'
  s.version = '0.0.1'
  s.summary = 'White Noise Rust library for the iOS notification service extension.'
  s.description = 'Builds the White Noise Rust static library for the iOS notification service extension without linking Flutter.'
  s.homepage = 'https://github.com/marmot-protocol/whitenoise'
  s.license = { :file => '../LICENSE' }
  s.authors = { 'White Noise' => 'dev@parres.org' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/librust_lib_whitenoise.a',
  }
  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../../rust rust_lib_whitenoise',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ['${BUILT_PRODUCTS_DIR}/librust_lib_whitenoise.a'],
  }
end
