import os
import logging
import httpx
import json
from typing import Optional, Dict, List, Any

logger = logging.getLogger(__name__)

class CustomSupabaseClient:
    """
    A custom Supabase client implementation that avoids the version compatibility issues
    by directly using httpx to make API requests.
    """
    
    def __init__(self, supabase_url: str, supabase_key: str):
        self.base_url = supabase_url
        self.api_key = supabase_key
        self.headers = {
            "apikey": supabase_key,
            "Authorization": f"Bearer {supabase_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }
        logger.info(f"CustomSupabaseClient initialized with URL: {supabase_url}")
    
    def table(self, table_name: str) -> 'TableQuery':
        """
        Create a query builder for a specific table
        """
        return TableQuery(self, table_name)
    
    def auth_get_user(self, token: str) -> Optional[Dict]:
        """
        Get user information from a JWT token
        """
        try:
            headers = {
                "apikey": self.api_key,
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            with httpx.Client() as client:
                response = client.get(
                    f"{self.base_url}/auth/v1/user",
                    headers=headers
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return {
                        "user": data,
                        "id": data.get("id")
                    }
                else:
                    logger.warning(f"Auth get user failed: {response.status_code} - {response.text}")
                    return None
        except Exception as e:
            logger.error(f"Error in auth_get_user: {str(e)}")
            return None
    
    def rpc(self, function_name: str, params: Dict) -> 'RPCQuery':
        """
        Call a PostgreSQL function
        """
        return RPCQuery(self, function_name, params)


class TableQuery:
    """
    Query builder for Supabase tables
    """
    
    def __init__(self, client: CustomSupabaseClient, table_name: str):
        self.client = client
        self.table_name = table_name
        self.query_params = {}
        self.filters = []
        self.selected_columns = "*"
        self.order_column = None
        self.order_direction = None
        self.limit_count = None
        self.count_option = None
    
    def select(self, columns: str, *, count: Optional[str] = None) -> 'TableQuery':
        """
        Select columns to return
        """
        self.selected_columns = columns
        self.count_option = count
        return self
    
    def eq(self, column: str, value: Any) -> 'TableQuery':
        """
        Add an equality filter
        """
        self.filters.append({
            "type": "eq",
            "column": column,
            "value": value
        })
        return self
    
    def lt(self, column: str, value: Any) -> 'TableQuery':
        """
        Add a less than filter
        """
        self.filters.append({
            "type": "lt",
            "column": column,
            "value": value
        })
        return self
    
    def gt(self, column: str, value: Any) -> 'TableQuery':
        """
        Add a greater than filter
        """
        self.filters.append({
            "type": "gt",
            "column": column,
            "value": value
        })
        return self
    
    def order(self, column: str, *, desc: bool = False) -> 'TableQuery':
        """
        Order results by a column
        """
        self.order_column = column
        self.order_direction = "desc" if desc else "asc"
        return self
    
    def limit(self, count: int) -> 'TableQuery':
        """
        Limit the number of results
        """
        self.limit_count = count
        return self
    
    def insert(self, data: Dict[str, Any]) -> 'TableQuery':
        """
        Insert data into the table
        """
        self.operation = "insert"
        self.data = data
        return self
    
    def update(self, data: Dict[str, Any]) -> 'TableQuery':
        """
        Update data in the table
        """
        self.operation = "update"
        self.data = data
        return self
    
    def delete(self) -> 'TableQuery':
        """
        Delete data from the table
        """
        self.operation = "delete"
        return self
    
    def _build_query_string(self) -> str:
        """
        Build the query string for API requests
        """
        params = []
        
        # Add select
        if hasattr(self, "selected_columns") and self.selected_columns != "*":
            params.append(f"select={self.selected_columns}")
        
        # Add count if requested
        if self.count_option:
            params.append(f"count={self.count_option}")
        
        # Add filters
        for filter in self.filters:
            if filter["type"] == "eq":
                params.append(f"{filter['column']}=eq.{filter['value']}")
            elif filter["type"] == "lt":
                params.append(f"{filter['column']}=lt.{filter['value']}")
            elif filter["type"] == "gt":
                params.append(f"{filter['column']}=gt.{filter['value']}")
        
        # Add ordering
        if self.order_column:
            params.append(f"order={self.order_column}.{self.order_direction}")
        
        # Add limit
        if self.limit_count:
            params.append(f"limit={self.limit_count}")
        
        return "&".join(params)
    
    def execute(self) -> 'QueryResult':
        """
        Execute the query
        """
        try:
            url = f"{self.client.base_url}/rest/v1/{self.table_name}"
            query_string = self._build_query_string()
            
            if query_string:
                url = f"{url}?{query_string}"
            
            with httpx.Client() as client:
                if hasattr(self, "operation"):
                    if self.operation == "insert":
                        response = client.post(
                            url,
                            headers=self.client.headers,
                            json=self.data
                        )
                    elif self.operation == "update":
                        # For update, we need to include the filters in the URL
                        response = client.patch(
                            url,
                            headers=self.client.headers,
                            json=self.data
                        )
                    elif self.operation == "delete":
                        response = client.delete(
                            url,
                            headers=self.client.headers
                        )
                else:
                    # Default to SELECT
                    response = client.get(
                        url,
                        headers=self.client.headers
                    )
                
                count = None
                if self.count_option and 'count' in response.headers:
                    count = int(response.headers['count'])
                
                if response.status_code >= 400:
                    logger.error(f"Supabase API error: {response.status_code} - {response.text}")
                    return QueryResult([], count, response.status_code)
                
                return QueryResult(response.json(), count, response.status_code)
        except Exception as e:
            logger.error(f"Error executing query: {str(e)}")
            return QueryResult([], None, 500)


class RPCQuery:
    """
    Query builder for Supabase RPC calls
    """
    
    def __init__(self, client: CustomSupabaseClient, function_name: str, params: Dict):
        self.client = client
        self.function_name = function_name
        self.params = params
    
    def execute(self) -> 'QueryResult':
        """
        Execute the RPC call
        """
        try:
            url = f"{self.client.base_url}/rest/v1/rpc/{self.function_name}"
            
            with httpx.Client() as client:
                response = client.post(
                    url,
                    headers=self.client.headers,
                    json=self.params
                )
                
                if response.status_code >= 400:
                    logger.error(f"Supabase RPC error: {response.status_code} - {response.text}")
                    return QueryResult([], None, response.status_code)
                
                return QueryResult(response.json(), None, response.status_code)
        except Exception as e:
            logger.error(f"Error executing RPC call: {str(e)}")
            return QueryResult([], None, 500)


class QueryResult:
    """
    Result of a Supabase query
    """
    
    def __init__(self, data: Any, count: Optional[int], status_code: int):
        self.data = data
        self.count = count
        self.status_code = status_code


def create_custom_client(supabase_url: str, supabase_key: str) -> CustomSupabaseClient:
    """
    Create a custom Supabase client
    """
    return CustomSupabaseClient(supabase_url, supabase_key)
