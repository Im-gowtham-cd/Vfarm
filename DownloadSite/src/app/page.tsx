import HomeStyle from './page.module.css'

export default function App() {
    return (
        <div className={HomeStyle.HomeContainer}>
            <nav>
                <h1>V Farm</h1>
                <ul>
                    <a href="">Home</a>
                    <a href="">Features</a>
                    <a href="">About</a>
                    <a href="">How it works ?</a>
                </ul>
                <a href="">Download <i className="bx bx-arrow-to-bottom" /></a>
            </nav>
            <section className={HomeStyle.Home}>
                <div className={HomeStyle.HomeContext}>
                    <p>We Farm , We Evolve</p>
                    <p>VFarm makes farming simple with easy tools and instant access to schemes, weather, and expert advice.
                        Fast, secure, and built to support every farmer’s success.</p>
                    <ul>
                        <a href="">Explore <i className="bx bx-arrow-in-up-right-circle" /> </a>
                    </ul>
                </div>
                <div className={HomeStyle.HomeDownload}>
                    <p>1K+ Downloads</p>
                    <p>500+ Users</p>
                    <p>Secure</p>
                    <p>Trusted</p>
                    <p>24/7 Support</p>
                    <p>Easy to Use</p>
                    <p>Reliable</p>
                    <p>Cloud Based</p>
                    <p>Affordable</p>
                    <p>Verified</p>

                </div>
                <div className={HomeStyle.HomeImage}>
                    <p></p>
                    {/* <p></p>
                    <p></p> */}
                </div>
            </section>
        </div>
    )
}