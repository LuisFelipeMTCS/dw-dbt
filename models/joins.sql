with prod as (
    select 
        ct.category_name, 
        sp.company_name as suppliers, 
        pd.product_name,
        pd.unit_price, 
        pd.product_id
    from {{ source('sources','products') }} pd
    left join {{ source('sources','suppliers') }} sp 
        on pd.supplier_id = sp.supplier_id
    left join {{ source('sources','categories') }} ct 
        on pd.category_id = ct.category_id
),

orddetai as (
    select 
        pd.*, 
        od.order_id, 
        od.quantity, 
        od.discount
    from {{ source('sources','order_details') }} od
    left join prod pd 
        on od.product_id = pd.product_id
),

ordrs as (
    select 
        ord.order_id,
        ord.order_date,
        cs.company_name as customer,
        em.first_name || ' ' || em.last_name as employee,
        sh.company_name as shipper
    from {{ source('sources','orders') }} ord
    left join {{ source('sources','customers') }} cs 
        on ord.customer_id = cs.customer_id
    left join {{ source('sources','employees') }} em 
        on ord.employee_id = em.employee_id
    left join {{ source('sources','shippers') }} sh 
        on ord.ship_via = sh.shipper_id
),

finaljoin as (
    select 
        od.order_id,
        ordrs.order_date,
        ordrs.customer,
        ordrs.employee,
        ordrs.shipper,
        od.product_name,
        od.category_name,
        od.suppliers,
        od.unit_price,
        od.quantity,
        od.discount,
        (od.unit_price * od.quantity * (1 - od.discount)) as total_value
    from orddetai od
    inner join ordrs 
        on od.order_id = ordrs.order_id
)

select * from finaljoin