import streamlit as st
import pandas as pd
import pymysql
import plotly.express as px
from datetime import date, time

def create_connection():
    try:
        connection = pymysql.connect(
            host="127.0.0.1",
            user="root",
            password="634155",
            database="Police",
            cursorclass=pymysql.cursors.DictCursor
        )
        return connection
    except Exception as e:
        st.error(f"Database Connection Error: {e}")
        return None

def fetch_data(query):
    connection = create_connection()
    if connection:
        try:
            with connection.cursor() as cursor:
                cursor.execute(query)
                result = cursor.fetchall()
                df = pd.DataFrame(result)
                return df
        finally:
            connection.close()
    else:
        return pd.DataFrame()

st.set_page_config(page_title="Police Dashboard", layout="wide")

st.title("🚓 Police Check Post Digital Ledger")
st.markdown("Real-time monitoring and insights for law enforcement")

st.header("📋 Police Logs Overview")
query = "SELECT * FROM police_log"
data = fetch_data(query)
st.dataframe(data, use_container_width=True)

st.header("📊 Key Metrics")
col1, col2, col3, col4 = st.columns(4)

with col1:
    total_stops = data.shape[0]
    st.metric("Total Police Stops", total_stops)

with col2:
    arrests = data[data["stop_outcome"].str.contains("arrest", case=False, na=False)].shape[0]
    st.metric("Total Arrests", arrests)

with col3:
    warnings = data[data["stop_outcome"].str.contains("warning", case=False, na=False)].shape[0]
    st.metric("Total Warnings", warnings)

with col4:
    drug_related = data[data["drugs_related_stop"] == 1].shape[0]
    st.metric("Drug Related Stops", drug_related)

st.header("📈 Insights & Charts")

if not data.empty:
    fig1 = px.histogram(data, x="violation", title="Violations by Type")
    st.plotly_chart(fig1, use_container_width=True)

    fig2 = px.pie(data, names="driver_gender", title="Stops by Driver Gender")
    st.plotly_chart(fig2, use_container_width=True)

#Advanced Queries
st.header("Advanced Queries")
selected_query = st.selectbox("select a Query to Run",[
    "Total Number of Police Stops",
    "Count of Stops by Violation Type",
    "Number of Arrests vs warnings",
    "Average Age of Drivers Stopped",
    "Top 5 Most Frequent Search Types",
    "Count of Stops by Gender",
    "Most Common Violation for Arrests"
])

query_map = {
    "Total Number of Police Stops": 
        "SELECT COUNT(*) AS total_stops FROM Police _log",

    "Count of Stops by Violation Type": 
        "SELECT violation, COUNT(*) AS count FROM Police_log GROUP BY violation ORDER BY count DESC",

    "Number of Arrests vs Warnings": 
        "SELECT stop_outcome, COUNT(*) AS count FROM Police_log GROUP BY stop_outcome",

    "Average Age of Drivers Stopped": 
        "SELECT AVG(driver_age) AS average_age FROM Police_log",

    "Top 5 Most Frequent Search Types": 
        "SELECT search_type, COUNT(*) AS count FROM Police_log WHERE search_type IS NOT NULL GROUP BY search_type ORDER BY count DESC LIMIT 5",

    "Count of Stops by Gender": 
        "SELECT driver_gender, COUNT(*) AS count FROM Police_log GROUP BY driver_gender",

    "Most Common Violation for Arrests": 
        "SELECT violation, COUNT(*) AS count FROM Police_log WHERE stop_outcome LIKE 'Arrests%' GROUP BY violation ORDER BY count DESC"
}

if st.button("Run Query"):
    result=fetch_data(query_map[selected_query])
    if not result.empty:
        st.write(result)
    else:
        st.warning("No results found for the selected query.")

st.markdown("___")
st.markdown("Built with ♥️ for Law Enforcement by Police")
st.header("Custom Natural Language Filter")

filtered_data = pd.DataFrame() 
predicted_outcome = None
predicted_violation = None
submitted = False

st.markdown("Fill in the details below to get a natural language prediction of the stop outcome based on existing data")

st.header("Add new police log & predict outcome and violation")
with st.form('new_log_form'):
    stop_date = st.date_input("Stop Date")
    stop_time = st.time_input("Stop Time")
    country_name = st.text_input("Country Name")
    driver_gender = st.selectbox("Driver Gender", ["male", "female"])
    driver_age = st.number_input("Driver Age", min_value=16, max_value=100)
    driver_race = st.text_input("Driver Race")
    search_conducted = st.selectbox("Was a search conducted?", ["0", "1"])
    search_type = st.text_input("SearchType")
    drugs_related_stop = st.selectbox("Was it drug related?", ["0", "1"])
    stop_duration = st.selectbox("Stop Duration", data["stop_duration"].dropna().unique())
    vehicle_number = st.text_input("Vehicle Number")

    submitted = st.form_submit_button("Predict Stop Outcome & Violation")
    
    if submitted:
        filtered_data = data[
            (data['driver_gender'] == driver_gender) &
            (data['driver_age'] == driver_age) &
            (data['search_conducted'] == int(search_conducted)) &
            (data['stop_duration'] == stop_duration) &
            (data['drugs_related_stop'] == int(drugs_related_stop))
        ]

        if not filtered_data.empty:
            predicted_outcome = filtered_data['stop_outcome'].mode()[0]
            predicted_violation = filtered_data['violation'].mode()[0]
        else:
            predicted_outcome = 'Warning'  
            predicted_violation = 'Speeding'

        
        search_text = "No search was conducted" if search_conducted == "0" else f"A {search_type} search was conducted"
        drug_text = "was not drug-related" if drugs_related_stop == "0" else "was drug-related"
        stop_time_formatted = stop_time.strftime("%I:%M %p")  # format 24h -> 12h with AM/PM

        summary = (f"A {driver_age}-year-old {driver_gender} driver was stopped for {predicted_violation} at {stop_time_formatted}. "
                   f"{search_text}, and they received a {predicted_outcome}. "
                   f"The stop lasted {stop_duration} and {drug_text}.")

        st.write(summary)