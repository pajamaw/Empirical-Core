"use strict";
import React from 'react'
import ProgressReport from './progress_report.jsx'
import MasteryStatus from './mastery_status.jsx'


export default  React.createClass({
  propTypes: {
    sourceUrl: React.PropTypes.string.isRequired,
    premiumStatus: React.PropTypes.string.isRequired
  },

  getInitialState: function() {
    return {
      student: {}
    };
  },

  columnDefinitions: function() {
    return [
      {
        name: 'Standard Level',
        field: 'section_name',
        sortByField: 'section_name',
        className: 'standard-level-column'
      },
      {
        name: 'Standard Name',
        field: 'name',
        sortByField: 'name',
        className: 'standard-name-column',
        customCell: function(row) {
          return (
            <a className="student-view" href={row['topic_students_href']}>{row['name']}</a>
          );
        }
      },
      {
        name: 'Activities',
        field: 'total_activity_count',
        sortByField: 'total_activity_count',
        className: 'activities-column'
      },
      {
        name: 'Average',
        field: 'average_score',
        sortByField: 'average_score',
        className: 'average-score-column',
        customCell: function(row) {
          return Math.round(row['average_score'] * 100) + '%';
        }
      },
      {
        name: 'Mastery Status',
        field: 'average_score',
        sortByField: 'average_score',
        className: 'mastery-status-column',
        customCell: function(row) {
          return <MasteryStatus score={row['average_score']} />;
        }
      }
    ];
  },

  sortDefinitions: function() {
    return {
      config: {
        name: 'natural',
        section_name: 'natural',
        total_activity_count: 'numeric',
        average_score: 'numeric'
      },
      default: {
        field: 'name',
        direction: 'asc'
      }
    };
  },

  onFetchSuccess: function(responseData) {
    this.setState({
      student: responseData.student
    });
  },

  render: function() {
    return (
      <ProgressReport columnDefinitions={this.columnDefinitions}
                         pagination={false}
                         sourceUrl={this.props.sourceUrl}
                         sortDefinitions={this.sortDefinitions}
                         onFetchSuccess={this.onFetchSuccess}
                         exportCsv={'standards_student_topics'}
                         jsonResultsKey={'topics'}
                         filterTypes={['unit']}
                         premiumStatus={this.props.premiumStatus}>
        <h2>Standards: {this.state.student.name}</h2>
      </ProgressReport>
    );
  }
});
