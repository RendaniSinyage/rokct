<?php

namespace App\Models;

use App\Helpers\Utility;
use App\Traits\Loadable;
use App\Traits\Reviewable;
use App\Traits\SetCurrency;
use Database\Factories\ShopFactory;
use Eloquent;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Relations\MorphOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

class Shop extends Model
{
    use HasFactory, SoftDeletes, Loadable, SetCurrency, Reviewable;

    protected $guarded = ['id'];

    const STATUS = [
        'new',
        'edited',
        'approved',
        'rejected',
        'inactive'
    ];

    // SHOP TYPE CONSTANTS
    const TYPE_RETAIL = 'retail';
    const TYPE_AGRI = 'agri';
    const TYPE_ALL = 'all';

    const TYPES = [
        self::TYPE_RETAIL => 'Retail Store',
        self::TYPE_AGRI => 'Agricultural Store',
        self::TYPE_ALL => 'All Types (Retail + Agricultural)',
    ];

    const DELIVERY_TIME_MINUTE  = 'minute';
    const DELIVERY_TIME_HOUR    = 'hour';
    const DELIVERY_TIME_DAY     = 'day';
    const DELIVERY_TIME_MONTH   = 'month';

    const ORDER_PAYMENT_AFTER  = 'after';
    const ORDER_PAYMENT_BEFORE = 'before';

    const DELIVERY_TIME_TYPE = [
        self::DELIVERY_TIME_MINUTE,
        self::DELIVERY_TIME_HOUR,
        self::DELIVERY_TIME_DAY,
        self::DELIVERY_TIME_MONTH,
    ];

    const ORDER_PAYMENTS = [
        self::ORDER_PAYMENT_AFTER,
        self::ORDER_PAYMENT_BEFORE,
    ];

    protected $casts = [
        'location'       		  => 'array',
        'delivery_time'  		  => 'array',
        'email_statuses' 		  => 'array',
        'close_time'     		  => 'date:H:i',
        'open'           		  => 'boolean',
		'new_order_after_payment' => 'boolean',
    ];

    /**
     * Check if shop is agricultural type
     */
    public function isAgricultural(): bool
    {
        return $this->type === self::TYPE_AGRI;
    }

    /**
     * Check if shop accepts all vehicle types (but still retail only)
     */
    public function acceptsAllVehicles(): bool
    {
        return $this->type === self::TYPE_ALL;
    }

    /**
     * Check if shop is retail type, null, or 'all' (all treated as retail)
     */
    public function isRetail(): bool
    {
        return $this->type === self::TYPE_RETAIL || is_null($this->type) || $this->type === self::TYPE_ALL;
    }

    /**
     * Get required vehicle types for this shop
     */
    public function getRequiredVehicleTypes(): array
    {
        if ($this->isAgricultural()) {
            // Agricultural only - trucks only
            return DeliveryVehicleType::getAgricultureVehicles();
        }

        // All other types (retail, null, 'all') use retail vehicles only
        return DeliveryVehicleType::getRetailVehicles();
    }

    /**
     * Get shop type display name
     */
    public function getTypeDisplayAttribute(): string
    {
        return self::TYPES[$this->type] ?? 'Retail Store';
    }

    /**
     * Scope for agricultural shops
     */
    public function scopeAgricultural($query)
    {
        return $query->where('type', self::TYPE_AGRI);
    }

    /**
     * Scope for retail shops
     */
    public function scopeRetail($query)
    {
        return $query->where(function($q) {
            $q->where('type', self::TYPE_RETAIL)
              ->orWhereNull('type');
        });
    }

    /**
     * Scope for shops accepting all vehicle types
     */
    public function scopeAllTypes($query)
    {
        return $query->where('type', self::TYPE_ALL);
    }

    public function getRatePriceAttribute(): ?float
    {
        if (request()->is('api/v1/dashboard/user/*') || request()->is('api/v1/rest/*')) {
            return $this->price * $this->currency();
        }

        return $this->price;
    }

    public function getRateMinAmountAttribute(): ?float
    {
        if (request()->is('api/v1/dashboard/user/*') || request()->is('api/v1/rest/*')) {
            return $this->min_amount * $this->currency();
        }

        return $this->min_amount;
    }

    public function getRatePricePerKmAttribute(): ?float
    {
        if (request()->is('dashboard/user') || request()->is('api/v1/rest/*')) {
            return $this->price_per_km * $this->currency();
        }

        return $this->price_per_km;
    }

    public function getAvgRateAttribute(): ?float
    {
        return $this->orders()->where([
            ['shop_id', $this->id],
            ['status', Order::STATUS_DELIVERED]
        ])->avg('rate');
    }

    public function bonus(): MorphOne
    {
        return $this->morphOne(Bonus::class, 'bonusable');
    }

    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(ShopTag::class, 'assign_shop_tags', 'shop_id', 'shop_tag_id');
    }

    public function discounts(): HasMany
    {
        return $this->hasMany(Discount::class);
    }

    public function translations(): HasMany
    {
        return $this->hasMany(ShopTranslation::class);
    }

    public function workingDays(): HasMany
    {
        return $this->hasMany(ShopWorkingDay::class);
    }

    public function closedDates(): HasMany
    {
        return $this->hasMany(ShopClosedDate::class);
    }

    public function translation(): HasOne
    {
        return $this->hasOne(ShopTranslation::class);
    }

    public function shopDeliverymanSetting(): HasOne
    {
        return $this->hasOne(ShopDeliverymanSetting::class);
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function shopPayments(): HasMany
    {
        return $this->hasMany(ShopPayment::class);
    }

    public function users(): HasManyThrough
    {
        return $this->hasManyThrough(User::class, Invitation::class,
            'shop_id', 'id', 'id', 'user_id');
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function invitations(): HasMany
    {
        return $this->hasMany(Invitation::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function deliveryZone(): HasOne
    {
        return $this->hasOne(DeliveryZone::class);
    }

    public function deliveryZones(): HasMany
	{
        return $this->hasMany(DeliveryZone::class);
    }

    public function reviews(): MorphMany
    {
        return $this->morphMany(Review::class, 'assignable');
    }

    public function subscription(): HasOne
    {
        return $this->hasOne(ShopSubscription::class, 'shop_id')
            ->whereDate('expired_at', '>=', today())
            ->where([
                'active' => 1
            ])
            ->orderByDesc('id');
    }

    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class, 'shop_categories', 'shop_id', 'category_id');
    }

    public function logs(): MorphMany
    {
        return $this->morphMany(ModelLog::class, 'model');
    }

	public function documents(): MorphMany
	{
		return $this->morphMany(Gallery::class, 'loadable')->where('type', 'shop-documents');
	}

    public function scopeFilter($query, $filter)
    {
        $orders  = [];

        if (data_get($filter, 'address.latitude') && data_get($filter, 'address.longitude')) {
            DeliveryZone::list()
				->whereNotNull('shop_id')
				->map(function (DeliveryZone $deliveryZone) use ($filter, &$orders) {

					$shop       = $deliveryZone->shop;

					$location   = data_get($deliveryZone->shop, 'location', []);

					$km         = (new Utility)->getDistance($location, data_get($filter, 'address', []));
					$rate       = data_get($filter, 'currency.rate', 1);

                	if (
                	    Utility::pointInPolygon(data_get($filter, 'address'), $deliveryZone->address)
                	) {
						$orders[$deliveryZone->shop_id] = (new Utility)->getPriceByDistance($km, $shop, $rate);
                	}

                	return null;
            	})
                ->reject(fn($data) => empty($data))
                ->toArray();

            arsort($orders);
        }

		$visibility = (int)Settings::where('key', 'by_subscription')->first()?->value;

		if ($visibility && request()->is('api/v1/rest/*')) {
			$filter['visibility'] = true;
		}

        $query
			->when(data_get($filter, 'slug'), fn($q, $slug) => $q->where('slug', $slug))
			->when(data_get($filter, 'user_id'), function ($q, $userId) {
                $q->where('user_id', $userId);
            })
            ->when(data_get($filter, 'status'), function ($q, $status) {
                $q->where('status', $status);
            })
            ->when(isset($filter['open']), function ($q) use($filter) {
                $q->where('open', $filter['open']);
            })
			->when(isset($filter['new_order_after_payment']), function ($q) use($filter) {
				$q->where('open', $filter['new_order_after_payment']);
			})
            ->when(isset($filter['visibility']), function ($q, $visibility) {
                $q->where('visibility', $visibility);
            })
            ->when(isset($filter['verify']), function ($q) use($filter) {
                $q->where('verify', $filter['verify']);
            })
            ->when(isset($filter['show_type']), function ($q, $showType) {
                $q->where('show_type', $showType);
            })
            ->when(data_get($filter, 'category_id'), function ($q, $categoryId) {
                $q->whereHas('categories', function ($query) use ($categoryId) {
                    $query->where('category_id', $categoryId);
                });
            })
            ->when(data_get($filter, 'bonus'), function (Builder $query) {
                $query->whereHas('bonus', function ($q) {
                    $q->where('expired_at', '>', now())->where('status', true);
                });
            })
            ->when(data_get($filter, 'deals'), function (Builder $query) {
                $query->where(function ($query) {
                    $query->whereHas('bonus', function ($q) {
                        $q->where('expired_at', '>', now())->where('status', true);
                    })->orWhereHas('discounts', function ($q) {
                        $q->where('end', '>=', now())->where('active', 1);
                    });
                });
            })
            ->when(data_get($filter, 'work_24_7'), function (Builder $query) {
                $query->whereHas('workingDays', fn($q) => $q
                    ->where('from', '01-00')
                    ->where('to', '>=', '23-00')
                );
            })
            ->when(data_get($filter, 'address'), function ($query) use ($filter, $orders) {
                $orderBys = ['new', 'old', 'best_sale', 'low_sale', 'high_rating', 'low_rating', 'trust_you'];
                $orderByIds = implode(',', array_keys($orders));

                $query
                    ->whereHas('deliveryZone')
                    ->when($orderByIds, function ($builder) use ($filter, $orderByIds, $orders, $orderBys) {

                        $builder->whereIn('id', array_keys($orders));

                        if (!in_array(data_get($filter, 'order_by'), $orderBys)) {
                            $builder->orderByRaw("FIELD(shops.id, $orderByIds) ASC");
                        }

                    });

            })
            ->when(data_get($filter, 'search'), function ($query, $search) {
                $query->where(function ($query) use ($search) {
                    $query
                        ->where('id', 'LIKE', "%$search%")
                        ->orWhere('phone', 'LIKE', "%$search%")
                        ->orWhereHas('translations', function ($q) use ($search) {
                            $q->where('title', 'LIKE', "%$search%")
                                ->select('id', 'shop_id', 'locale', 'title');
                        });
                });
            })
            ->when(data_get($filter, 'take'), function (Builder $query, $take) {

                $query->whereHas('tags', function (Builder $q) use ($take) {
                    $q->when(is_array($take), fn($q) => $q->whereIn('id', $take), fn($q) => $q->where('id', $take));
                });

            })
            ->when(data_get($filter, 'free_delivery'), function (Builder $q) {
                $q->where([
                    ['price', '=', 0],
                    ['price_per_km', '=', 0],
                ]);
            })
            ->when(data_get($filter, 'fast_delivery'), function (Builder $q) {
                $q
                    ->where('delivery_time->type','minute')
                    ->orWhere('delivery_time->type','day')
                    ->orWhere('delivery_time->type','month')
                    ->orderByRaw('CAST(JSON_EXTRACT(delivery_time, "$.from") AS from)', 'desc');
            })
            ->when(data_get($filter, 'has_discount'), function (Builder $query) {
                $query->whereHas('discounts', function ($q) {
                    $q
                        ->where('end', '>=', now())
                        ->where('active', 1)
                        ->whereNull('deleted_at');
                });
            })
            ->when(isset($filter['deleted_at']), fn($q) => $q->onlyTrashed());
    }
}

