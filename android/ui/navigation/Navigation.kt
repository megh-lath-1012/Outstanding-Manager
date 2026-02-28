package com.example.outstandingmanager.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.outstandingmanager.ui.screens.*
import com.example.outstandingmanager.viewmodel.OutstandingViewModel

sealed class Screen(val route: String) {
    object Dashboard : Screen("dashboard")
    object AddCompany : Screen("add_company")
    object CompanyDetails : Screen("company/{companyId}") {
        fun createRoute(companyId: String) = "company/$companyId"
    }
    object AddTransaction : Screen("company/{companyId}/add_transaction") {
        fun createRoute(companyId: String) = "company/$companyId/add_transaction"
    }
    object MakePayment : Screen("company/{companyId}/make_payment") {
        fun createRoute(companyId: String) = "company/$companyId/make_payment"
    }
}

@Composable
fun OutstandingNavHost(
    viewModel: OutstandingViewModel
) {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = Screen.Dashboard.route
    ) {
        composable(Screen.Dashboard.route) {
            DashboardScreen(
                viewModel = viewModel,
                onNavigateToAddCompany = {
                    navController.navigate(Screen.AddCompany.route)
                },
                onNavigateToCompany = { companyId ->
                    navController.navigate(Screen.CompanyDetails.createRoute(companyId))
                }
            )
        }

        composable(Screen.AddCompany.route) {
            AddCompanyScreen(
                viewModel = viewModel,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(
            route = Screen.CompanyDetails.route,
            arguments = listOf(navArgument("companyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val companyId = backStackEntry.arguments?.getString("companyId") ?: return@composable
            CompanyDetailsScreen(
                viewModel = viewModel,
                companyId = companyId,
                onNavigateBack = {
                    navController.popBackStack()
                },
                onNavigateToAddTransaction = {
                    navController.navigate(Screen.AddTransaction.createRoute(companyId))
                },
                onNavigateToMakePayment = {
                    navController.navigate(Screen.MakePayment.createRoute(companyId))
                }
            )
        }

        composable(
            route = Screen.AddTransaction.route,
            arguments = listOf(navArgument("companyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val companyId = backStackEntry.arguments?.getString("companyId") ?: return@composable
            AddTransactionScreen(
                viewModel = viewModel,
                companyId = companyId,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        composable(
            route = Screen.MakePayment.route,
            arguments = listOf(navArgument("companyId") { type = NavType.StringType })
        ) { backStackEntry ->
            val companyId = backStackEntry.arguments?.getString("companyId") ?: return@composable
            MakePaymentScreen(
                viewModel = viewModel,
                companyId = companyId,
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}
