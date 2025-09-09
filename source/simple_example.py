#!/usr/bin/env python3
"""
Simple examples demonstrating Apache Livy capabilities
This script shows basic Spark operations via Livy REST API
"""

from livy import LivySession, SessionKind
import textwrap
import time

# Configuration
LIVY_SERVER = "http://127.0.0.1:8998"

def example_1_basic_spark():
    """Basic Spark operations"""
    print("🔥 Example 1: Basic Spark Operations")
    print("=" * 40)
    
    code = textwrap.dedent("""
    from pyspark.sql import SparkSession
    
    # Create Spark session
    spark = SparkSession.builder.appName("BasicExample").getOrCreate()
    
    # Create a simple RDD
    numbers = spark.sparkContext.parallelize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    
    # Basic operations
    total = numbers.sum()
    count = numbers.count()
    squares = numbers.map(lambda x: x * x).collect()
    
    print(f"Numbers: {numbers.collect()}")
    print(f"Total: {total}")
    print(f"Count: {count}")
    print(f"Squares: {squares}")
    
    spark.stop()
    """)
    
    with LivySession.create(LIVY_SERVER, kind=SessionKind.PYSPARK) as session:
        session.run(code)

def example_2_dataframe_operations():
    """DataFrame operations with sample data"""
    print("\n📊 Example 2: DataFrame Operations")
    print("=" * 40)
    
    create_dataframe = textwrap.dedent("""
    from pyspark.sql import SparkSession
    from pyspark.sql.functions import col, avg, max, min, count
    
    spark = SparkSession.builder.appName("DataFrameExample").getOrCreate()
    
    # Create sample data
    data = [
        ("Alice", 25, "Engineer", 75000),
        ("Bob", 30, "Manager", 85000),
        ("Charlie", 35, "Engineer", 70000),
        ("Diana", 28, "Analyst", 65000),
        ("Eve", 32, "Manager", 90000)
    ]
    
    columns = ["Name", "Age", "Role", "Salary"]
    df = spark.createDataFrame(data, columns)
    
    print("Sample DataFrame:")
    df.show()
    
    print("\\nDataFrame Schema:")
    df.printSchema()
    """)
    
    analyze_data = textwrap.dedent("""
    # Basic statistics
    print("\\nBasic Statistics:")
    df.describe().show()
    
    # Group by operations
    print("\\nAverage Salary by Role:")
    df.groupBy("Role").agg(
        avg("Salary").alias("avg_salary"),
        count("Name").alias("count")
    ).show()
    
    # Filter operations
    print("\\nEngineers only:")
    df.filter(col("Role") == "Engineer").show()
    
    # Salary range
    print(f"\\nSalary Range: ${df.agg(min('Salary')).collect()[0][0]} - ${df.agg(max('Salary')).collect()[0][0]}")
    """)
    
    with LivySession.create(LIVY_SERVER, kind=SessionKind.PYSPARK) as session:
        session.run(create_dataframe)
        session.run(analyze_data)
        
        # Get data back as Pandas DataFrame
        session.run("pandas_df = df.toPandas()")
        local_df = session.read("pandas_df")
        
        print(f"\nLocal Pandas DataFrame shape: {local_df.shape}")
        print(local_df)

def example_3_file_operations():
    """File I/O operations"""
    print("\n📁 Example 3: File I/O Operations")
    print("=" * 40)
    
    create_and_save = textwrap.dedent("""
    from pyspark.sql import SparkSession
    
    spark = SparkSession.builder.appName("FileExample").getOrCreate()
    
    # Create sample sales data
    sales_data = [
        ("2023-01", "ProductA", 1000, 50.0),
        ("2023-01", "ProductB", 1500, 75.0),
        ("2023-02", "ProductA", 1200, 50.0),
        ("2023-02", "ProductB", 1800, 75.0),
        ("2023-03", "ProductA", 900, 50.0),
        ("2023-03", "ProductB", 2000, 75.0),
    ]
    
    columns = ["Month", "Product", "Quantity", "Price"]
    sales_df = spark.createDataFrame(sales_data, columns)
    
    print("Sales Data:")
    sales_df.show()
    
    # Calculate revenue
    sales_df = sales_df.withColumn("Revenue", sales_df.Quantity * sales_df.Price)
    
    print("\\nWith Revenue Column:")
    sales_df.show()
    
    # Save as Parquet
    sales_df.write.mode("overwrite").parquet("/opt/workspace/sales_data.parquet")
    print("\\nData saved to /opt/workspace/sales_data.parquet")
    """)
    
    read_and_analyze = textwrap.dedent("""
    # Read the data back
    loaded_df = spark.read.parquet("/opt/workspace/sales_data.parquet")
    
    print("\\nLoaded data from Parquet:")
    loaded_df.show()
    
    # Monthly revenue summary
    monthly_revenue = loaded_df.groupBy("Month").sum("Revenue").orderBy("Month")
    print("\\nMonthly Revenue Summary:")
    monthly_revenue.show()
    
    # Product performance
    product_performance = loaded_df.groupBy("Product").agg(
        {"Quantity": "sum", "Revenue": "sum"}
    )
    print("\\nProduct Performance:")
    product_performance.show()
    
    spark.stop()
    """)
    
    with LivySession.create(LIVY_SERVER, kind=SessionKind.PYSPARK) as session:
        session.run(create_and_save)
        session.run(read_and_analyze)

def example_4_spark_sql():
    """SQL operations with Spark"""
    print("\n🔍 Example 4: Spark SQL")
    print("=" * 40)
    
    setup_tables = textwrap.dedent("""
    from pyspark.sql import SparkSession
    
    spark = SparkSession.builder.appName("SparkSQLExample").getOrCreate()
    
    # Create customers table
    customers = [
        (1, "John Doe", "john@email.com", "New York"),
        (2, "Jane Smith", "jane@email.com", "California"),
        (3, "Bob Johnson", "bob@email.com", "Texas"),
        (4, "Alice Brown", "alice@email.com", "New York")
    ]
    
    customer_columns = ["id", "name", "email", "state"]
    customers_df = spark.createDataFrame(customers, customer_columns)
    customers_df.createOrReplaceTempView("customers")
    
    # Create orders table
    orders = [
        (101, 1, "2023-01-15", 250.0),
        (102, 2, "2023-01-16", 175.0),
        (103, 1, "2023-01-20", 300.0),
        (104, 3, "2023-01-22", 125.0),
        (105, 2, "2023-01-25", 200.0)
    ]
    
    order_columns = ["order_id", "customer_id", "order_date", "amount"]
    orders_df = spark.createDataFrame(orders, order_columns)
    orders_df.createOrReplaceTempView("orders")
    
    print("Customers table:")
    customers_df.show()
    
    print("\\nOrders table:")
    orders_df.show()
    """)
    
    run_queries = textwrap.dedent("""
    # SQL Query 1: Customer order summary
    query1 = '''
    SELECT 
        c.name,
        c.state,
        COUNT(o.order_id) as total_orders,
        SUM(o.amount) as total_spent
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id
    GROUP BY c.id, c.name, c.state
    ORDER BY total_spent DESC
    '''
    
    print("\\nCustomer Order Summary:")
    spark.sql(query1).show()
    
    # SQL Query 2: State-wise revenue
    query2 = '''
    SELECT 
        c.state,
        COUNT(DISTINCT c.id) as customer_count,
        SUM(o.amount) as total_revenue
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    GROUP BY c.state
    ORDER BY total_revenue DESC
    '''
    
    print("\\nState-wise Revenue:")
    spark.sql(query2).show()
    
    # SQL Query 3: High-value customers
    query3 = '''
    SELECT 
        c.name,
        c.email,
        SUM(o.amount) as total_spent
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    GROUP BY c.id, c.name, c.email
    HAVING SUM(o.amount) > 200
    ORDER BY total_spent DESC
    '''
    
    print("\\nHigh-Value Customers (>$200):")
    spark.sql(query3).show()
    
    spark.stop()
    """)
    
    with LivySession.create(LIVY_SERVER, kind=SessionKind.PYSPARK) as session:
        session.run(setup_tables)
        session.run(run_queries)

def main():
    """Run all examples"""
    print("🚀 Apache Livy & Spark Examples")
    print("=" * 50)
    
    try:
        print(f"Connecting to Livy server at {LIVY_SERVER}...")
        
        # Run all examples
        example_1_basic_spark()
        example_2_dataframe_operations()
        example_3_file_operations()
        example_4_spark_sql()
        
        print("\n✅ All examples completed successfully!")
        
    except Exception as e:
        print(f"\n❌ Error running examples: {str(e)}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())


