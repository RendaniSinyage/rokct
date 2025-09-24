<?php

namespace App\Http\Controllers\API\v1\Rest\Resources;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\ExpenseIndexRequest;
use App\Http\Requests\Api\ExpenseStoreRequest;
use App\Http\Requests\Api\ExpenseUpdateRequest;
use App\Http\Requests\Api\ExpensePartialUpdateRequest;
use App\Http\Requests\Api\ExpenseStatisticsRequest;
use App\Models\Resources\Expense;
use App\Models\Resources\ExpenseType;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Log;

class ExpensesController extends Controller
{
    public function index(ExpenseIndexRequest $request)
    {
        try {
            $query = Expense::query()
                ->where('shop_id', $request->shop_id);

            if ($request->type_id) {
                $query->where('type_id', $request->type_id);
            }

            if ($request->start_date) {
                $query->whereDate('created_at', '>=', $request->start_date);
            }

            if ($request->end_date) {
                $query->whereDate('created_at', '<=', $request->end_date);
            }

            $expenses = $query->orderBy('created_at', 'desc')
                ->paginate($request->per_page ?? 15);

            return response()->json([
                'success' => true,
                'data' => $expenses
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching expenses: ' . $e->getMessage()
            ], 500);
        }
    }

    public function store(ExpenseStoreRequest $request)
    {
        try {
            $expense = Expense::create($request->validated());

            return response()->json([
                'success' => true,
                'data' => $expense
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error creating expense: ' . $e->getMessage()
            ], 500);
        }
    }

    public function show($id)
    {
        try {
            $expense = Expense::findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $expense
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching expense: ' . $e->getMessage()
            ], 500);
        }
    }

    public function update(ExpenseUpdateRequest $request, $id)
    {
        try {
            $expense = Expense::findOrFail($id);
            $expense->update($request->validated());

            return response()->json([
                'success' => true,
                'data' => $expense
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating expense: ' . $e->getMessage()
            ], 500);
        }
    }

    public function partialUpdate(ExpensePartialUpdateRequest $request, $id)
    {
        try {
            $expense = Expense::findOrFail($id);
            
            // Only update provided fields
            $expense->update(array_filter($request->validated(), function ($value) {
                return $value !== null;
            }));

            return response()->json([
                'success' => true,
                'data' => $expense
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating expense: ' . $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $expense = Expense::findOrFail($id);
            $expense->delete();

            return response()->json([
                'success' => true,
                'message' => 'Expense deleted successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error deleting expense: ' . $e->getMessage()
            ], 500);
        }
    }

   public function getTypes()
{
    try {
        // Debug information
        \Log::info('Attempting to fetch expense types');
        
        // Check if model class exists
        if (!class_exists(ExpenseType::class)) {
            \Log::error('ExpenseType model class not found');
            return response()->json([
                'success' => false,
                'message' => 'ExpenseType model not found'
            ], 500);
        }

        // Check if table exists
        if (!Schema::hasTable('expenses_type')) {
            \Log::error('expenses_type table does not exist');
            return response()->json([
                'success' => false,
                'message' => 'Expenses type table not found'
            ], 500);
        }

        // Try raw query first
        $rawTypes = DB::select('SELECT * FROM expenses_type');
        \Log::info('Raw query result:', ['count' => count($rawTypes)]);

        if (empty($rawTypes)) {
            return response()->json([
                'success' => true,
                'data' => []
            ]);
        }

        // If raw query works, try with model
        $types = ExpenseType::select(['id', 'name'])
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $types
        ]);
    } catch (\Exception $e) {
        \Log::error('Error in getTypes: ' . $e->getMessage());
        \Log::error('Stack trace: ' . $e->getTraceAsString());
        
        return response()->json([
            'success' => false,
            'message' => 'Error fetching expense types: ' . $e->getMessage()
        ], 500);
    }
}

    public function getStatistics(ExpenseStatisticsRequest $request)
    {
        try {
            $query = Expense::query()
                ->where('shop_id', $request->shop_id);

            if ($request->start_date) {
                $query->whereDate('created_at', '>=', $request->start_date);
            }

            if ($request->end_date) {
                $query->whereDate('created_at', '<=', $request->end_date);
            }

            $stats = [
                'total_price' => $query->sum('price'),
                'count' => $query->count(),
                'by_type' => $query->select('type_id', DB::raw('COUNT(*) as count'), DB::raw('SUM(price) as total'))
                    ->groupBy('type_id')
                    ->with('type:id,name')
                    ->get()
            ];

            return response()->json([
                'success' => true,
                'data' => $stats
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching statistics: ' . $e->getMessage()
            ], 500);
        }
    }
}
