<?php

namespace App\Http\Controllers\API\v1\Rest;

use App\Helpers\ResponseError;
use App\Http\Requests\FilterParamsRequest;
use App\Http\Resources\BannerResource;
use App\Models\Banner;
use App\Repositories\BannerRepository\BannerRepository;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BannerController extends RestBaseController
{
    private BannerRepository $repository;

    /**
     * @param BannerRepository $repository
     */
    public function __construct(BannerRepository $repository)
    {
        parent::__construct();

        $this->repository = $repository;
    }

    /**
     * Display a listing of the resource.
     *
     * @param FilterParamsRequest $request
     * @return AnonymousResourceCollection
     */
    public function paginate(FilterParamsRequest $request): AnonymousResourceCollection
    {
        $banners = $this->repository->bannersPaginate($request->merge(['active' => 1])->all());

        return BannerResource::collection($banners);
    }

    /**
     * Display the specified resource.
     *
     * @param int $id
     * @return JsonResponse
     */
    public function show(int $id): JsonResponse
    {
        $banner = $this->repository->bannerDetails($id);

        if (empty($banner)) {
            return $this->onErrorResponse([
                'code'      => ResponseError::ERROR_404,
                'message'   => __('errors.' . ResponseError::ERROR_404, locale: $this->language)
            ]);
        }

        // Deduplicate shops if needed
        if ($banner->shops && $banner->shops->isNotEmpty()) {
            $uniqueShops = $banner->shops->unique('id');
            $banner->setRelation('shops', $uniqueShops->values());
        }

        return $this->successResponse(
            __('errors.' . ResponseError::SUCCESS, locale: $this->language),
            BannerResource::make($banner)
        );
    }

    /**
     * @param int $id
     * @return JsonResponse
     */
    public function likedBanner(int $id): JsonResponse
    {
        $banner = Banner::find($id);

        if (empty($banner)) {
            return $this->onErrorResponse([
                'code'    => ResponseError::ERROR_404,
                'message' => __('errors.' . ResponseError::ERROR_404, locale: $this->language)
            ]);
        }

        $banner->liked();

        return $this->successResponse(
            __('errors.' . ResponseError::RECORD_WAS_SUCCESSFULLY_UPDATED, locale: $this->language)
        );
    }

    /**
 * Display a listing of the resource.
 *
 * @param FilterParamsRequest $request
 * @return array|JsonResponse
 */
public function adsPaginate(FilterParamsRequest $request)
{
    $response = $this->repository->adsPaginate($request->merge(['active' => 1])->all());
    
    // Add debug logging to see the structure
    \Log::info("Original ads response", [
        'structure' => json_encode(array_keys($response)),
        'data_count' => isset($response['data']) ? count($response['data']) : 0
    ]);
    
    // Convert entire response to array and back to ensure consistent structure
    $responseArray = json_decode(json_encode($response), true);
    
    if (isset($responseArray['data']) && is_array($responseArray['data'])) {
        foreach ($responseArray['data'] as $key => $banner) {
            // Ensure all boolean fields are true booleans
            if (isset($banner['active'])) {
                $responseArray['data'][$key]['active'] = (bool)$banner['active'];
            }
            
            if (isset($banner['clickable'])) {
                $responseArray['data'][$key]['clickable'] = (bool)$banner['clickable'];
            }
            
            if (isset($banner['input'])) {
                $responseArray['data'][$key]['input'] = (bool)$banner['input'];
            }
            
            // Deduplicate shops
            if (isset($banner['shops']) && is_array($banner['shops'])) {
                $uniqueShops = [];
                $shopIds = [];
                
                foreach ($banner['shops'] as $shop) {
                    if (!isset($shop['id']) || !in_array($shop['id'], $shopIds)) {
                        if (isset($shop['id'])) {
                            $shopIds[] = $shop['id'];
                        }
                        
                        // Fix boolean fields in shop
                        if (isset($shop['open'])) {
                            $shop['open'] = (bool)$shop['open'];
                        }
                        
                        if (isset($shop['visibility'])) {
                            $shop['visibility'] = (bool)$shop['visibility'];
                        }
                        
                        if (isset($shop['verify'])) {
                            $shop['verify'] = (bool)$shop['verify'];
                        }
                        
                        $uniqueShops[] = $shop;
                    }
                }
                
                $responseArray['data'][$key]['shops'] = $uniqueShops;
            }
        }
    }
    
    // Instead of returning an array, return a properly formatted JSON response
    return response()->json($responseArray);
}

   /**
 * Display a listing of the resource.
 *
 * @param int $id
 * @return JsonResponse
 */
public function adsShow(int $id): JsonResponse
{
    $models = $this->repository->adsShow($id);
    
    if (empty($models)) {
        return $this->onErrorResponse([
            'code'      => ResponseError::ERROR_404,
            'message'   => __('errors.' . ResponseError::ERROR_404, locale: $this->language)
        ]);
    }

    // Make sure $models is an object before using get_class
    if (is_object($models)) {
        // Only log the class if it's an object
        \Log::info("Original adsShow model for ID $id is " . get_class($models));
    } else {
        \Log::info("Original adsShow model for ID $id is not an object, but " . gettype($models));
    }

    // Convert to array for manipulation
    $data = is_object($models) ? json_decode(json_encode($models), true) : $models;
    
    // Fix boolean fields
    if (isset($data['active'])) {
        $data['active'] = (bool)$data['active'];
    }
    
    if (isset($data['clickable'])) {
        $data['clickable'] = (bool)$data['clickable'];
    }
    
    if (isset($data['input'])) {
        $data['input'] = (bool)$data['input'];
    }
    
    // Deduplicate shops
    if (isset($data['shops']) && is_array($data['shops'])) {
        $uniqueShops = [];
        $shopIds = [];
        
        foreach ($data['shops'] as $shop) {
            if (!isset($shop['id']) || !in_array($shop['id'], $shopIds)) {
                if (isset($shop['id'])) {
                    $shopIds[] = $shop['id'];
                }
                
                // Fix boolean fields in shop
                if (isset($shop['open'])) {
                    $shop['open'] = (bool)$shop['open'];
                }
                
                if (isset($shop['visibility'])) {
                    $shop['visibility'] = (bool)$shop['visibility'];
                }
                
                if (isset($shop['verify'])) {
                    $shop['verify'] = (bool)$shop['verify'];
                }
                
                $uniqueShops[] = $shop;
            }
        }
        
        $data['shops'] = $uniqueShops;
    }
    
    $response = [
        'timestamp' => date('Y-m-d H:i:s'),
        'status' => true,
        'message' => "Successfully",
        'data' => $data
    ];
    
    return response()->json($response);
}
}
