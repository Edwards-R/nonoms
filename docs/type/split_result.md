# split_result

## Signature
    name text,
	children integer[]

## Composition

### name
The name of the new understanding

### children
The ids of the children to assign to this name

## Explanation

A type designed for standard assigning of a split result. It is intended to be used when an understanding is split into multiple new understandings.

Given an original understanding `u_original` being split into two new understandings `u_new_1` and `u_new_2`, this will be represented by two `split_result` types. All children from `u_original` must be divided up between the new understandings (in this case `u_new_1` and `u_new_2`). For example, if `u_original` has 5 child understandings `c_1`, `c_2`, `c_3`, `c_4`, and `c_5`, then these 5 must be found in `u_new_1` and `u_new_2`. In this example 1-3 will be assigned to `u_new_1`, and 4-5 will be assigned to `u_new_2`

    u_new_1::split_result

        name: u_new_1
        children: [1,2,3]

    u_new_2::split_result

        name: u_new_2
        children: [4,5]

## Example
    SELECT ('test'::text, ARRAY[1,2,3])::nomenclature.split_result
---

    SELECT ARRAY[
        ('test'::text, ARRAY[1,2,3]),
        ('test'::text, ARRAY[1,2,3]),
        ('test'::text, ARRAY[1,2,3])
    ]::nomenclature.split_result[]