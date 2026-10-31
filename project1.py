from datetime import datetime
from airflow import DAG
from airflow.sdk import Param  
from airflow.providers.standard.operators.bash import BashOperator  
from airflow.providers.standard.operators.python import BranchPythonOperator  

with DAG(
    dag_id="project1-workflow",
    start_date=datetime(2015, 12, 1),
    schedule=None,
    params={
        "dags_home": Param("/home/hadoop/airflow/dags", type="string"),
        "input_dir": Param("/user/hadoop/input", type="string"),
        "output_mr_dir": Param("/user/hadoop/output/mr_output", type="string"),
        "output_dir": Param("/user/hadoop/output/hive_output", type="string"),
        "classic_or_streaming": Param("streaming", enum=["classic", "streaming"]),
    },
    render_template_as_native_obj=True,
    catchup=False,  
) as dag:

    # Clean HDFS directories
    clean_output_mr_dir = BashOperator(
        task_id="clean_output_mr_dir",
        bash_command=(
            "if hadoop fs -test -d {{ params.output_mr_dir }}; "
            "then hadoop fs -rm -f -r {{ params.output_mr_dir }}; fi"
        ),
    )

    clean_output_dir = BashOperator(
        task_id="clean_output_dir",
        bash_command=(
            "if hadoop fs -test -d {{ params.output_dir }}; "
            "then hadoop fs -rm -f -r {{ params.output_dir }}; fi"
        ),
    )

    # Branching logic
    def _pick_classic_or_streaming(params):
        if params["classic_or_streaming"] == "classic":
            return "mapreduce_classic"
        else:
            return "hadoop_streaming"

    pick_classic_or_streaming = BranchPythonOperator(
        task_id="pick_classic_or_streaming",
        python_callable=_pick_classic_or_streaming,
        op_kwargs={"params": dag.params},
    )

    # Classic MapReduce (Placeholder)
    mapreduce_classic = BashOperator(
        task_id="mapreduce_classic",
        bash_command="echo 'Classic MR not used in this project variant.'",
    )

    # Streaming MapReduce execution
    hadoop_streaming = BashOperator(
        task_id="hadoop_streaming",
        bash_command=(
            "bash {{ params.dags_home }}/project_files/mapreduce/run_mr.sh "
            "{{ params.input_dir }}/datasource1 {{ params.output_mr_dir }}"
        ),
    )

    # Hive pipeline execution
    hive = BashOperator(
        task_id="hive",
        bash_command=(
            "bash {{ params.dags_home }}/project_files/hive/run_hive.sh "
            "{{ params.output_mr_dir }} {{ params.input_dir }}/datasource4 {{ params.output_dir }}"
        ),
        trigger_rule="none_failed",
    )

    # Fetch and display results
    get_output = BashOperator(
        task_id="get_output",
        bash_command=(
            "hadoop fs -cat {{ params.output_dir }}/* | head -n 10"
        ),
        trigger_rule="none_failed",
    )

    # Define task dependencies
    [clean_output_mr_dir, clean_output_dir] >> pick_classic_or_streaming
    pick_classic_or_streaming >> [mapreduce_classic, hadoop_streaming]
    [mapreduce_classic, hadoop_streaming] >> hive
    hive >> get_output