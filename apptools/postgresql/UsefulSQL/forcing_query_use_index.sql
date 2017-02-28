
 create table test_no_index(id int);

 set enable_seqscan to false;

 explain select * from test_no_index where id > 12;

 create index new_idx_test_no_index on test_no_index(id);

 explain select * from test_no_index where id > 12;

 set random_page_cost = 2;
