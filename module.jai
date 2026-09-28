#module_parameters (USE_D3D12_PREVIEW := false);

/// Set of flags recommended for use in D3D12MA::ALLOCATOR_DESC::Flags for optimal performance.
D3D12MA_RECOMMENDED_ALLOCATOR_FLAGS :: D3D12MA.ALLOCATOR_FLAGS.DEFAULT_POOLS_NOT_ZEROED | .MSAA_TEXTURES_ALWAYS_COMMITTED;

#if D3D12MA_CREATE_NOT_ZEROED_AVAILABLE {
    D3D12MA_RECOMMENDED_HEAP_FLAGS :: D3D12_HEAP_FLAGS.CREATE_NOT_ZEROED;
} else {
    /// Set of flags recommended for use in D3D12MA::POOL_DESC::HeapFlags for optimal performance.
    D3D12MA_RECOMMENDED_HEAP_FLAGS :: D3D12_HEAP_FLAGS.NONE;
}

/// Set of flags recommended for use in D3D12MA::POOL_DESC::Flags for optimal performance.
D3D12MA_RECOMMENDED_POOL_FLAGS :: D3D12MA.POOL_FLAGS.MSAA_TEXTURES_ALWAYS_COMMITTED;

#scope_module

#import "Windows";
#import "dxgi";
#if USE_D3D12_PREVIEW {
    #import "d3d12-preview";
} else {
    #import "d3d12";
}

#if OS == .WINDOWS {
    #load "windows.jai";
}
