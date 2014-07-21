module.exports = {
  all: {
    files: [
      'doc/**/*',
      'public/**/*',
      'src/**/*',
      'Brocfile.js'
    ],
    tasks: ['build']
  },
  livereload: {
    options: { livereload: true },
    files: [
      'dist/**/*.html',
      'dist/**/*.css'
    ]
  }
};
